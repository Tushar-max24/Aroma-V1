import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'gemini_recipe_service.dart';
import 'cache_database_service.dart';
import '../models/recipe_cache_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeRecipeService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://3.108.110.151:5001",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  // Generate dynamic recipe preferences using Gemini
  Future<Map<String, dynamic>> _generateDynamicPreferences() async {
    try {
      final prompt = """
Generate diverse recipe preferences for home cooking. Return ONLY a valid JSON object.

{
  "Cuisine_Preference": "[Random from: Italian, Mexican, Indian, Chinese, Japanese, Thai, American, Mediterranean]",
  "Dietary_Restrictions": "[Random from: Vegetarian, Non-Vegetarian, Vegan, Gluten-Free, None]",
  "Cookware_Available": "[Random selection of 2-3 from: Gas Stove, Oven, Microwave, Air Fryer, Pan, Pressure Cooker, Grill]",
  "Meal_Type": "[Random selection of 1-2 from: Breakfast, Lunch, Dinner, Snack]",
  "Cooking_Time": "[Random from: < 15 min, < 30 min, < 45 min, < 1 hour]",
  "Serving": "[Random from: 1, 2, 3, 4]",
  "Ingredients_Available": "[Random selection of 4-6 common ingredients]"
}

Rules:
- Be realistic and diverse
- Ingredients should be common household items
- Make it suitable for home cooking
""";

      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=${dotenv.env['GEMINI_API_KEY'] ?? ''}",
      );

      final response = await Dio().post(
        url.toString(),
        options: Options(headers: {"Content-Type": "application/json"}),
        data: jsonEncode({
          "contents": [
            {
              "parts": [{"text": prompt}]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final decoded = response.data;
        if (decoded is Map<String, dynamic>) {
          String text = decoded["candidates"][0]["content"]["parts"][0]["text"];
          
          // Extract JSON from response
          var cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final jsonStart = cleaned.indexOf('{');
          final jsonEnd = cleaned.lastIndexOf('}');
          
          if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
            final jsonStr = cleaned.substring(jsonStart, jsonEnd + 1).trim();
            return jsonDecode(jsonStr);
          }
        }
      }
      
      // Fallback to default preferences if Gemini fails
      return _getDefaultPreferences();
    } catch (e) {
      print('❌ Error generating preferences with Gemini: $e');
      return _getDefaultPreferences();
    }
  }

  // Default fallback preferences
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      "Cuisine_Preference": "Indian",
      "Dietary_Restrictions": "Vegetarian",
      "Cookware_Available": ["Gas Stove", "Pan"],
      "Meal_Type": ["Breakfast"],
      "Cooking_Time": "< 15 min",
      "Serving": "1",
      "Ingredients_Available": ["Potato", "rice", "Onion", "Tomato"],
    };
  }

  // Generate hash for caching
  String _generatePreferenceHash(Map<String, dynamic> preferences) {
    final prefString = jsonEncode(preferences);
    final bytes = utf8.encode(prefString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<List<dynamic>> generateHomeRecipes() async {
    try {
      // Step 1: Generate dynamic preferences
      final preferences = await _generateDynamicPreferences();
      final preferenceHash = _generatePreferenceHash(preferences);
      
      print("🎲 Generated Preferences: $preferences");
      print("🔑 Preference Hash: $preferenceHash");
      
      // Step 2: Check cache first (24-hour cache)
      final cachedRecipes = await CacheDatabaseService.getGeneratedRecipes(preferenceHash);
      
      if (cachedRecipes != null) {
        final cacheAge = DateTime.now().difference(cachedRecipes.cachedAt);
        if (cacheAge.inHours < 24) {
          print("✅ Using cached recipes (age: ${cacheAge.inHours}h)");
          return cachedRecipes.recipes;
        } else {
          print("⏰ Cache expired (${cacheAge.inHours}h old), fetching fresh data");
        }
      } else {
        print("🔍 No cache found, fetching fresh data");
      }
      
      // Step 3: Fetch fresh recipes from backend
      final response = await _dio.post(
        "/generate-recipes",
        data: preferences,
      );

      print("🔥 RAW HOME API RESPONSE: ${response.data}");

      // Step 4: Process response
      List<dynamic> recipes = [];
      
      if (response.data is Map) {
        if (response.data['Recipes'] != null) {
          recipes = response.data['Recipes'] as List;
        } else if (response.data['recipes'] != null) {
          recipes = response.data['recipes'] as List;
        } else if (response.data['data'] != null) {
          recipes = response.data['data'] as List;
        }
      } else if (response.data is List) {
        recipes = response.data as List;
      }
      
      if (recipes.isEmpty) {
        throw Exception('No recipes found in API response');
      }
      
      // Step 5: Cache the results with images and cuisine info
      final recipeImages = <String, String>{};
      final cuisineType = preferences['Cuisine_Preference'] as String;
      
      // Extract images from recipes if available
      for (var recipe in recipes) {
        if (recipe is Map) {
          // Handle different image field names
          String? recipeName;
          String? imageUrl;
          
          // Try different name fields
          recipeName = recipe['name']?.toString() ?? 
                      recipe['dish_name']?.toString() ?? 
                      recipe['title']?.toString();
          
          // Try different image field structures
          if (recipe['image'] != null) {
            if (recipe['image'] is Map) {
              imageUrl = recipe['image']['image_url']?.toString() ?? 
                         recipe['image']['url']?.toString();
            } else {
              imageUrl = recipe['image'].toString();
            }
          } else if (recipe['Image'] != null && recipe['Image'] is Map) {
            imageUrl = recipe['Image']['image_url']?.toString() ?? 
                       recipe['Image']['url']?.toString();
          }
          
          if (recipeName != null && imageUrl != null) {
            recipeImages[recipeName] = imageUrl;
          }
        }
      }
      
      // Cache the results
      final cacheData = GeneratedRecipeCache(
        preferenceHash: preferenceHash,
        recipes: List<Map<String, dynamic>>.from(recipes),
        recipeImages: recipeImages,
        cuisine: cuisineType,
        cachedAt: DateTime.now(),
      );
      
      await CacheDatabaseService.cacheGeneratedRecipes(cacheData);
      print("💾 Cached recipes for 24 hours");
      
      // Step 6: Clean up expired cache
      await CacheDatabaseService.clearExpiredCache();
      
      return recipes;
      
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      
      // Fallback: try to get any cached data regardless of age
      try {
        final allCached = await _getAnyCachedRecipes();
        if (allCached.isNotEmpty) {
          print("🔄 Using fallback cache data");
          return allCached;
        }
      } catch (cacheError) {
        print('❌ Fallback cache also failed: $cacheError');
      }
      
      rethrow;
    }
  }
  
  // Helper method to get any cached recipes as fallback
  Future<List<dynamic>> _getAnyCachedRecipes() async {
    final db = await CacheDatabaseService.database;
    final maps = await db.query(
      CacheDatabaseService.generatedRecipeTable,
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      final map = maps.first;
      final cache = GeneratedRecipeCache.fromJson({
        'preference_hash': map['preference_hash'],
        'recipes': jsonDecode(map['recipes']?.toString() ?? '[]'),
        'recipe_images': jsonDecode(map['recipe_images']?.toString() ?? '{}'),
        'cuisine': map['cuisine'],
        'cached_at': map['cached_at'],
      });
      return cache.recipes;
    }
    
    return [];
  }
  
  // Method to manually clear cache (for testing)
  Future<void> clearCache() async {
    await CacheDatabaseService.clearCache();
    print("🧹 Cache cleared manually");
  }
  
  // Method to check cache status
  Future<Map<String, dynamic>> getCacheStatus() async {
    final db = await CacheDatabaseService.database;
    final maps = await db.query(CacheDatabaseService.generatedRecipeTable);
    
    if (maps.isNotEmpty) {
      final map = maps.first;
      final cachedAt = DateTime.parse(map['cached_at'].toString());
      final age = DateTime.now().difference(cachedAt);
      
      return {
        'hasCache': true,
        'cachedAt': cachedAt.toIso8601String(),
        'ageHours': age.inHours,
        'isExpired': age.inHours >= 24,
        'preferenceHash': map['preference_hash'],
        'cuisine': map['cuisine'],
      };
    }
    
    return {
      'hasCache': false,
    };
  }
}