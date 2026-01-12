import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'recipe_detail_service.dart';
import 'mongo_ingredient_service.dart';
import 'enhanced_ingredient_image_service.dart';
import 'enhanced_recipe_image_service.dart';

class CookingPreferenceRecipeService {
  static bool _isInitialized = false;
  static String get _mongoApiBaseUrl => dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Cache for storing preference-based recipes to avoid repeated API calls
  static final Map<String, Map<String, dynamic>> _preferenceRecipeCache = {};

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Cooking Preference Recipe Service initialized with MongoDB-first caching');
      }
    }
  }

  /// Normalize recipe name and preference for consistent database storage
  static String _normalizeRecipeName(String recipeName) {
    return recipeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get recipe details based on cooking preference with MongoDB-first caching
  /// 1. First check MongoDB for existing recipe with matching preference
  /// 2. If found, return cached recipe details
  /// 3. If not found, generate new recipe and store in MongoDB
  static Future<Map<String, dynamic>> getRecipeByPreference(
    String recipeName, 
    String cookingPreference, {
    List<String>? availableIngredients,
  }) async {
    await initialize();
    
    final normalizedName = _normalizeRecipeName(recipeName);
    final normalizedPreference = cookingPreference.toLowerCase().trim();
    
    if (kDebugMode) {
      print('🔍 [Preference Recipe] Getting recipe: "$recipeName"');
      print('🔍 [Preference Recipe] Cooking preference: "$cookingPreference"');
      print('🔍 [Preference Recipe] Available ingredients: ${availableIngredients?.length ?? 0}');
    }
    
    try {
      // Step 1: Check cache first
      final cacheKey = '${normalizedName}_$normalizedPreference';
      if (_preferenceRecipeCache.containsKey(cacheKey)) {
        final cachedRecipe = _preferenceRecipeCache[cacheKey]!;
        if (kDebugMode) {
          print('✅ [Preference Recipe] FOUND IN MEMORY CACHE: $recipeName ($cookingPreference)');
          print('📦 [Preference Recipe] Cache keys: ${cachedRecipe.keys.toList()}');
        }
        return cachedRecipe;
      }

      // Step 2: Check MongoDB for recipe with matching preference
      final mongoRecipe = await _getRecipeFromMongoDB(normalizedName, normalizedPreference);
      if (mongoRecipe != null) {
        if (kDebugMode) {
          print('✅ [Preference Recipe] FOUND IN MONGODB: $recipeName ($cookingPreference)');
          print('📦 [Preference Recipe] MongoDB keys: ${mongoRecipe.keys.toList()}');
          print('🖼️ [Preference Recipe] Image source: ${mongoRecipe['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
        }
        
        // Cache in memory for faster access
        _preferenceRecipeCache[cacheKey] = mongoRecipe;
        return mongoRecipe;
      }

      if (kDebugMode) {
        print('❌ [Preference Recipe] NOT FOUND IN MONGODB: $recipeName ($cookingPreference)');
        print('🔄 [Preference Recipe] Generating new recipe from backend...');
      }

      // Step 3: Generate new recipe from backend with preference
      final newRecipe = await _generateRecipeFromBackend(
        recipeName, 
        cookingPreference, 
        availableIngredients: availableIngredients
      );

      if (kDebugMode) {
        print('✅ [Preference Recipe] GENERATED FROM BACKEND: $recipeName ($cookingPreference)');
        print('📦 [Preference Recipe] Generated keys: ${newRecipe.keys.toList()}');
        print('🖼️ [Preference Recipe] Generated image: ${newRecipe['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
      }

      // Step 4: Store in MongoDB for future caching
      await _storeRecipeInMongoDB(normalizedName, normalizedPreference, newRecipe);
      
      // Cache in memory
      _preferenceRecipeCache[cacheKey] = newRecipe;
      
      return newRecipe;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Preference Recipe] Error getting recipe: $e');
      }
      rethrow;
    }
  }

  /// Get recipe from MongoDB by name and preference
  static Future<Map<String, dynamic>?> _getRecipeFromMongoDB(String normalizedName, String preference) async {
    try {
      final url = Uri.parse("$_mongoApiBaseUrl/api/recipes/preference/$normalizedName/$preference");
      
      final response = await http.get(url);

      if (kDebugMode) {
        print('📌 [Preference Recipe] MongoDB Get Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (kDebugMode) {
          print('📌 [Preference Recipe] MongoDB Data keys: ${result.keys.toList()}');
          print('📌 [Preference Recipe] MongoDB Image URL: ${result['image_url']}');
          print('📌 [Preference Recipe] MongoDB Tags: ${result['tags']}');
          print('📌 [Preference Recipe] MongoDB Needed Ingredients: ${result['needed_ingredients']}');
        }
        return result;
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ [Preference Recipe] Recipe not found in MongoDB: $normalizedName ($preference)');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('❌ [Preference Recipe] Failed to fetch recipe: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Preference Recipe] Error fetching from MongoDB: $e');
      }
      return null;
    }
  }

  /// Generate new recipe from backend with cooking preference
  static Future<Map<String, dynamic>> _generateRecipeFromBackend(
    String recipeName, 
    String cookingPreference, {
    List<String>? availableIngredients,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 [Preference Recipe] Calling backend API for: $recipeName ($cookingPreference)');
      }

      // Call backend with preference and available ingredients
      final response = await _dio.post(
        "/generate-recipe-with-preference",
        data: {
          "dish_name": recipeName,
          "cooking_preference": cookingPreference,
          "available_ingredients": availableIngredients ?? [],
        },
      );

      if (response.statusCode == 200) {
        final recipeData = response.data;
        if (kDebugMode) {
          print('✅ [Preference Recipe] Backend response received');
          print('📦 [Preference Recipe] Backend keys: ${recipeData.keys.toList()}');
        }
        return recipeData;
      } else {
        throw Exception('Backend API failed: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Preference Recipe] Backend API error: $e');
      }
      
      // Fallback to existing recipe detail service
      if (kDebugMode) {
        print('🔄 [Preference Recipe] Falling back to existing recipe service');
      }
      return await RecipeDetailService.fetchRecipeDetails(recipeName);
    }
  }

  /// Store recipe in MongoDB with preference, tags, and needed ingredients
  static Future<bool> _storeRecipeInMongoDB(
    String recipeName, 
    String preference, 
    Map<String, dynamic> recipeData
  ) async {
    try {
      if (kDebugMode) {
        print('💾 [Preference Recipe] Storing recipe in MongoDB: $recipeName ($preference)');
      }

      // Format recipe data with enhanced schema
      final formattedRecipeData = {
        'name': recipeName,
        'cooking_preference': preference,
        'image_url': recipeData['image_url'] ?? '',
        'cuisine': recipeData['cuisine'] ?? 'Unknown',
        'cook_time': recipeData['cook_time'] ?? 'Unknown',
        'servings': recipeData['servings'] ?? 1,
        'description': recipeData['description'] ?? '',
        'tags': recipeData['tags'] ?? [],
        'needed_ingredients': recipeData['needed_ingredients'] ?? [],
        'ingredients': recipeData['ingredients'] ?? [],
        'cooking_steps': recipeData['cooking_steps'] ?? [],
        'nutrition': recipeData['nutrition'] ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final url = Uri.parse("$_mongoApiBaseUrl/api/recipes");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(formattedRecipeData),
      ).timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print('📌 [Preference Recipe] MongoDB Store Response: ${response.statusCode}');
        print('📦 [Preference Recipe] Stored data keys: ${formattedRecipeData.keys.toList()}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [Preference Recipe] Successfully stored in MongoDB: $recipeName ($preference)');
          final responseData = jsonDecode(response.body);
          print('📝 [Preference Recipe] Recipe ID: ${responseData['recipeId'] ?? responseData['_id']}');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ [Preference Recipe] Failed to store in MongoDB: ${response.statusCode}');
          print('❌ [Preference Recipe] Response body: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Preference Recipe] Error storing in MongoDB: $e');
      }
      return false;
    }
  }

  /// Clear memory cache
  static void clearMemoryCache() {
    _preferenceRecipeCache.clear();
    if (kDebugMode) {
      print('🗑️ [Preference Recipe] Memory cache cleared');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'service': 'Cooking Preference Recipe Service',
      'workflow': 'MongoDB-first with preference-based caching',
      'memory_cache_size': _preferenceRecipeCache.length,
      'cache_keys': _preferenceRecipeCache.keys.toList(),
      'mongo_api_base_url': _mongoApiBaseUrl,
      'backend_base_url': _baseUrl,
    };
  }

  /// Batch preload recipes for given preferences
  static Future<void> preloadRecipesByPreferences(
    List<String> recipeNames, 
    List<String> preferences, {
    List<String>? availableIngredients,
  }) async {
    await initialize();
    
    if (kDebugMode) {
      print('🔄 [Preference Recipe] Preloading ${recipeNames.length} recipes for ${preferences.length} preferences');
    }
    
    for (final recipeName in recipeNames) {
      for (final preference in preferences) {
        try {
          await getRecipeByPreference(
            recipeName, 
            preference, 
            availableIngredients: availableIngredients
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ [Preference Recipe] Error preloading $recipeName ($preference): $e');
          }
        }
      }
    }
    
    if (kDebugMode) {
      print('✅ [Preference Recipe] Preloading completed');
    }
  }
}
