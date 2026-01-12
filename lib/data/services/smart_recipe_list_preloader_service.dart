import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'recipe_detail_service.dart';
import 'enhanced_recipe_detail_service.dart';
import 'enhanced_recipe_image_service.dart';
import 'enhanced_ingredient_image_service.dart';
import 'mongo_ingredient_service.dart';
import 'cooking_preference_recipe_service.dart';

class SmartRecipeListPreloaderService {
  static bool _isInitialized = false;
  static String get _mongoApiBaseUrl => dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";
  
  // Cache for storing preloaded recipe data during recipe list phase
  static final Map<String, Map<String, dynamic>> _recipeListCache = {};
  static final Map<String, Map<String, dynamic>> _ingredientListCache = {};

  /// Initialize service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Smart Recipe List Preloader Service initialized');
      }
    }
  }

  /// Smart preloading during recipe list screen before navigation
  /// 1. Check MongoDB for existing recipes with cooking preferences
  /// 2. Preload all recipe data (text, images, steps, ingredients, bottom sheet data)
  /// 3. Cache everything in memory for instant navigation
  static Future<Map<String, dynamic>> preloadRecipeDataBeforeNavigation({
    required List<Map<String, dynamic>> recipes,
    required Map<String, dynamic> preferences,
    required List<Map<String, dynamic>> availableIngredients,
  }) async {
    await initialize();
    
    if (kDebugMode) {
      print('🚀 [Recipe List Preloader] Starting smart preloading before navigation');
      print('📦 [Recipe List Preloader] Recipes to preload: ${recipes.length}');
      print('🍳 [Recipe List Preloader] Cooking preferences: ${preferences.keys.toList()}');
      print('🥘 [Recipe List Preloader] Available ingredients: ${availableIngredients.length}');
    }

    final stopwatch = Stopwatch()..start();
    int preloadedRecipes = 0;
    int preloadedIngredients = 0;
    int cachedImages = 0;

    try {
      // Extract cooking preference from preferences
      final cookingPreference = preferences['cuisine']?.toString().toLowerCase() ?? 'general';
      final cookingTime = preferences['time']?.toString() ?? '30';
      final cookware = preferences['cookware']?.toString() ?? 'pan';

      if (kDebugMode) {
        print('🍳 [Recipe List Preloader] Extracted preference: $cookingPreference');
        print('⏰ [Recipe List Preloader] Cooking time: $cookingTime');
        print('🍳 [Recipe List Preloader] Cookware: $cookware');
      }

      // Phase 1: Smart Recipe Preloading with MongoDB-first caching
      for (final recipe in recipes) {
        try {
          final recipeName = recipe["recipe_name"] ?? recipe["Dish"] ?? "Unknown Dish";
          
          // Check if already preloaded
          if (!_recipeListCache.containsKey(recipeName)) {
            if (kDebugMode) {
              print('🔄 [Recipe List Preloader] Preloading recipe: $recipeName');
            }

            // Step 1: Try to get recipe from MongoDB with cooking preference
            final mongoRecipe = await _getRecipeFromMongoDBWithPreference(recipeName, cookingPreference);
            
            Map<String, dynamic> recipeDetails;
            
            if (mongoRecipe != null) {
              // Found in MongoDB
              recipeDetails = mongoRecipe;
              if (kDebugMode) {
                print('✅ [Recipe List Preloader] FOUND IN MONGODB: $recipeName ($cookingPreference)');
                print('📦 [Recipe List Preloader] MongoDB keys: ${recipeDetails.keys.toList()}');
                print('🖼️ [Recipe List Preloader] MongoDB image: ${recipeDetails['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
              }
            } else {
              // Not in MongoDB, fetch from backend with preference
              recipeDetails = await _fetchRecipeFromBackendWithPreference(
                recipeName, 
                cookingPreference, 
                preferences,
                availableIngredients
              );
              
              if (kDebugMode) {
                print('🔄 [Recipe List Preloader] FETCHED FROM BACKEND: $recipeName ($cookingPreference)');
                print('📦 [Recipe List Preloader] Backend keys: ${recipeDetails.keys.toList()}');
                print('🖼️ [Recipe List Preloader] Backend image: ${recipeDetails['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
              }
            }

            // Step 2: Preload ingredient images for this recipe
            await _preloadIngredientImagesForRecipe(recipeDetails);

            // Step 3: Cache recipe in memory
            _recipeListCache[recipeName] = recipeDetails;
            preloadedRecipes++;
            
            if (kDebugMode) {
              print('✅ [Recipe List Preloader] Preloaded complete recipe: $recipeName');
              print('🏷️ [Recipe List Preloader] Cache Source: ${mongoRecipe != null ? 'MONGODB' : 'BACKEND'}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ [Recipe List Preloader] Error preloading recipe: $e');
          }
        }
      }

      // Phase 2: Batch preload common ingredient images
      await _batchPreloadIngredientImages(availableIngredients);

      stopwatch.stop();
      
      if (kDebugMode) {
        print('✅ [Recipe List Preloader] Smart preloading completed in ${stopwatch.elapsedMilliseconds}ms');
        print('📊 [Recipe List Preloader] Preloaded recipes: $preloadedRecipes');
        print('🥘 [Recipe List Preloader] Preloaded ingredients: $preloadedIngredients');
        print('🖼️ [Recipe List Preloader] Cached images: $cachedImages');
        print('💾 [Recipe List Preloader] Memory cache size: ${_recipeListCache.length + _ingredientListCache.length}');
      }

      return {
        'success': true,
        'preloadedRecipes': preloadedRecipes,
        'preloadedIngredients': preloadedIngredients,
        'cachedImages': cachedImages,
        'totalTime': stopwatch.elapsedMilliseconds,
        'cacheSize': _recipeListCache.length + _ingredientListCache.length,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Smart preloading failed: $e');
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'preloadedRecipes': preloadedRecipes,
        'preloadedIngredients': preloadedIngredients,
        'cachedImages': cachedImages,
      };
    }
  }

  /// Get recipe from MongoDB with cooking preference
  static Future<Map<String, dynamic>?> _getRecipeFromMongoDBWithPreference(String recipeName, String preference) async {
    try {
      final url = Uri.parse("$_mongoApiBaseUrl/api/recipes/preference/$recipeName/$preference");
      
      final response = await http.get(url);

      if (kDebugMode) {
        print('📌 [Recipe List Preloader] MongoDB Preference Get Response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ [Recipe List Preloader] Recipe not found in MongoDB: $recipeName ($preference)');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('❌ [Recipe List Preloader] Failed to fetch recipe: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Error fetching from MongoDB: $e');
      }
      return null;
    }
  }

  /// Fetch recipe from backend with cooking preference
  static Future<Map<String, dynamic>> _fetchRecipeFromBackendWithPreference(
    String recipeName,
    String cookingPreference,
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> availableIngredients,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 [Recipe List Preloader] Calling backend API for: $recipeName ($cookingPreference)');
      }

      // Use cooking preference service for backend call
      final recipeDetails = await CookingPreferenceRecipeService.getRecipeByPreference(
        recipeName,
        cookingPreference,
        availableIngredients: availableIngredients.map((ing) => ing['name']?.toString() ?? '').toList(),
      );
      
      return recipeDetails;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Backend API error: $e');
      }
      
      // Fallback to existing recipe detail service
      return await RecipeDetailService.fetchRecipeDetails(recipeName);
    }
  }

  /// Preload ingredient images for a specific recipe
  static Future<void> _preloadIngredientImagesForRecipe(Map<String, dynamic> recipeDetails) async {
    try {
      // Extract ingredients from different possible locations
      final List<Map<String, dynamic>> allIngredients = [];
      
      // 1. Check main ingredients list
      if (recipeDetails['ingredients'] != null) {
        final ingredients = recipeDetails['ingredients'] as List;
        for (final ingredient in ingredients) {
          if (ingredient is Map<String, dynamic>) {
            allIngredients.add(ingredient);
          } else if (ingredient is String) {
            allIngredients.add({'name': ingredient});
          }
        }
      }

      // 2. Check cooking steps for ingredients
      if (recipeDetails['cooking_steps'] != null) {
        final steps = recipeDetails['cooking_steps'] as List;
        for (final step in steps) {
          if (step is Map<String, dynamic> && step['ingredients'] != null) {
            final stepIngredients = step['ingredients'] as List;
            for (final ingredient in stepIngredients) {
              if (ingredient is Map<String, dynamic>) {
                allIngredients.add(ingredient);
              } else if (ingredient is String) {
                allIngredients.add({'name': ingredient});
              }
            }
          }
        }
      }

      // 3. Check needed ingredients
      if (recipeDetails['needed_ingredients'] != null) {
        final neededIngredients = recipeDetails['needed_ingredients'] as List;
        for (final ingredient in neededIngredients) {
          if (ingredient is Map<String, dynamic>) {
            allIngredients.add(ingredient);
          } else if (ingredient is String) {
            allIngredients.add({'name': ingredient});
          }
        }
      }

      // Preload ingredient images
      for (final ingredient in allIngredients) {
        final ingredientName = ingredient['name']?.toString() ?? '';
        if (ingredientName.isNotEmpty && !_ingredientListCache.containsKey(ingredientName)) {
          final imageUrl = await EnhancedIngredientImageService.getIngredientImage(ingredientName);
          
          _ingredientListCache[ingredientName] = {
            'name': ingredientName,
            'image_url': imageUrl,
            'cached_at': DateTime.now().toIso8601String(),
          };
          
          if (kDebugMode) {
            print('✅ [Recipe List Preloader] Preloaded ingredient image: $ingredientName');
            print('🏷️ [Recipe List Preloader] Ingredient Cache Source: ${imageUrl?.startsWith('assets') == true ? 'ASSET' : 'MONGODB/BACKEND'}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Error preloading ingredient images: $e');
      }
    }
  }

  /// Batch preload ingredient images
  static Future<void> _batchPreloadIngredientImages(List<Map<String, dynamic>> availableIngredients) async {
    try {
      for (final ingredient in availableIngredients) {
        final ingredientName = ingredient['name']?.toString() ?? '';
        if (ingredientName.isNotEmpty && !_ingredientListCache.containsKey(ingredientName)) {
          final imageUrl = await EnhancedIngredientImageService.getIngredientImage(ingredientName);
          
          _ingredientListCache[ingredientName] = {
            'name': ingredientName,
            'image_url': imageUrl,
            'cached_at': DateTime.now().toIso8601String(),
          };
          
          if (kDebugMode) {
            print('✅ [Recipe List Preloader] Batch preloaded ingredient: $ingredientName');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Error in batch ingredient preloading: $e');
      }
    }
  }

  /// Get preloaded recipe from memory cache
  static Map<String, dynamic>? getPreloadedRecipe(String recipeName) {
    final normalizedName = recipeName.toLowerCase().trim();
    return _recipeListCache[normalizedName];
  }

  /// Get preloaded ingredient from memory cache
  static Map<String, dynamic>? getPreloadedIngredient(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return _ingredientListCache[normalizedName];
  }

  /// Check if recipe is preloaded
  static bool isRecipePreloaded(String recipeName) {
    final normalizedName = recipeName.toLowerCase().trim();
    return _recipeListCache.containsKey(normalizedName);
  }

  /// Check if ingredient is preloaded
  static bool isIngredientPreloaded(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return _ingredientListCache.containsKey(normalizedName);
  }

  /// Get all preloaded recipes
  static Map<String, Map<String, dynamic>> getAllPreloadedRecipes() {
    return Map.from(_recipeListCache);
  }

  /// Get all preloaded ingredients
  static Map<String, Map<String, dynamic>> getAllPreloadedIngredients() {
    return Map.from(_ingredientListCache);
  }

  /// Get access to recipe list cache (for state persistence)
  static Map<String, Map<String, dynamic>> get recipeListCache => _recipeListCache;

  /// Get access to ingredient list cache (for state persistence)
  static Map<String, Map<String, dynamic>> get ingredientListCache => _ingredientListCache;

  /// Clear memory cache
  static void clearMemoryCache() {
    _recipeListCache.clear();
    _ingredientListCache.clear();
    if (kDebugMode) {
      print('🗑️ [Recipe List Preloader] Memory cache cleared');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'service': 'Smart Recipe List Preloader Service',
      'workflow': 'MongoDB-first with recipe list preloading',
      'memory_cache_recipes': _recipeListCache.length,
      'memory_cache_ingredients': _ingredientListCache.length,
      'total_cached_items': _recipeListCache.length + _ingredientListCache.length,
    };
  }

  /// Sync preloaded data to MongoDB for persistence
  static Future<void> syncToMongoDB() async {
    if (kDebugMode) {
      print('🔄 [Recipe List Preloader] Syncing preloaded data to MongoDB...');
    }

    try {
      // Sync recipes to MongoDB
      for (final entry in _recipeListCache.entries) {
        final recipeName = entry.key;
        final recipeData = entry.value;
        
        // Store recipe in MongoDB using enhanced service
        await EnhancedRecipeDetailService.fetchRecipeDetailsWithIngredientCaching(recipeName);
      }

      // Sync ingredients to MongoDB
      for (final entry in _ingredientListCache.entries) {
        final ingredientName = entry.key;
        final ingredientData = entry.value;
        final imageUrl = ingredientData['image_url'] as String;
        
        // Store ingredient in MongoDB using enhanced service
        await EnhancedIngredientImageService.getIngredientImage(ingredientName, imageUrl: imageUrl);
      }

      if (kDebugMode) {
        print('✅ [Recipe List Preloader] Sync to MongoDB completed');
        print('📦 [Recipe List Preloader] Synced recipes: ${_recipeListCache.length}');
        print('🥘 [Recipe List Preloader] Synced ingredients: ${_ingredientListCache.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Preloader] Sync to MongoDB failed: $e');
      }
    }
  }
}
