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

class SmartSplashRecipeCacheService {
  static bool _isInitialized = false;
  static String get _mongoApiBaseUrl => dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";
  
  // Cache for storing preloaded recipes during splash
  static final Map<String, Map<String, dynamic>> _splashRecipeCache = {};
  static final Map<String, Map<String, dynamic>> _splashIngredientCache = {};

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Smart Splash Recipe Cache Service initialized');
      }
    }
  }

  /// Smart preloading during splash screen with MongoDB-first caching
  /// 1. Check MongoDB for existing recipes and ingredients
  /// 2. Cache images using enhanced services
  /// 3. Store in memory for instant access after splash
  static Future<Map<String, dynamic>> smartPreloadDuringSplash({
    List<String>? recipeNames,
    List<String>? ingredientNames,
    List<String>? cookingPreferences,
  }) async {
    await initialize();
    
    if (kDebugMode) {
      print('🚀 [Smart Splash] Starting smart preloading during splash');
      print('📦 [Smart Splash] Recipes to preload: ${recipeNames?.length ?? 0}');
      print('🥘 [Smart Splash] Ingredients to preload: ${ingredientNames?.length ?? 0}');
      print('🍳 [Smart Splash] Cooking preferences: ${cookingPreferences?.length ?? 0}');
    }

    final stopwatch = Stopwatch()..start();
    int preloadedRecipes = 0;
    int preloadedIngredients = 0;
    int cachedImages = 0;

    try {
      // Phase 1: Smart Recipe Preloading with MongoDB-first caching
      if (recipeNames != null && recipeNames!.isNotEmpty) {
        if (kDebugMode) {
          print('🔄 [Smart Splash] Phase 1: Smart recipe preloading');
        }

        for (final recipeName in recipeNames!) {
          try {
            // Check if already in cache
            if (!_splashRecipeCache.containsKey(recipeName)) {
              // Use enhanced recipe detail service with ingredient caching
              final recipeDetails = await EnhancedRecipeDetailService.fetchRecipeDetailsWithIngredientCaching(recipeName);
              
              if (recipeDetails.isNotEmpty) {
                _splashRecipeCache[recipeName] = recipeDetails;
                preloadedRecipes++;
                
                if (kDebugMode) {
                  print('✅ [Smart Splash] Preloaded recipe: $recipeName');
                  print('📦 [Smart Splash] Recipe keys: ${recipeDetails.keys.toList()}');
                  print('🖼️ [Smart Splash] Recipe image: ${recipeDetails['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [Smart Splash] Error preloading recipe $recipeName: $e');
            }
          }
        }
      }

      // Phase 2: Smart Ingredient Preloading with MongoDB-first caching
      if (ingredientNames != null && ingredientNames!.isNotEmpty) {
        if (kDebugMode) {
          print('🔄 [Smart Splash] Phase 2: Smart ingredient preloading');
        }

        for (final ingredientName in ingredientNames!) {
          try {
            // Check if already in cache
            if (!_splashIngredientCache.containsKey(ingredientName)) {
              // Use enhanced ingredient image service with MongoDB-first caching
              final imageUrl = await EnhancedIngredientImageService.getIngredientImage(ingredientName);
              
              _splashIngredientCache[ingredientName] = {
                'name': ingredientName,
                'image_url': imageUrl,
                'cached_at': DateTime.now().toIso8601String(),
              };
              preloadedIngredients++;
              cachedImages++;
              
              if (kDebugMode) {
                print('✅ [Smart Splash] Preloaded ingredient: $ingredientName');
                print('🏷️ [Smart Splash] Cache Source: ${imageUrl?.startsWith('assets') == true ? 'ASSET' : 'MONGODB/BACKEND'}');
                print('🖼️ [Smart Splash] Image: ${imageUrl?.substring(0, 50) ?? 'No image'}...');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [Smart Splash] Error preloading ingredient $ingredientName: $e');
            }
          }
        }
      }

      // Phase 3: Preference-based Recipe Preloading
      if (cookingPreferences != null && cookingPreferences!.isNotEmpty) {
        if (kDebugMode) {
          print('🔄 [Smart Splash] Phase 3: Preference-based recipe preloading');
        }

        for (final preference in cookingPreferences!) {
          try {
            // Create sample recipe names for each preference
            final sampleRecipes = _generateSampleRecipesForPreference(preference);
            
            for (final recipeName in sampleRecipes) {
              if (!_splashRecipeCache.containsKey(recipeName)) {
                // Use cooking preference service for smart caching
                final recipeDetails = await CookingPreferenceRecipeService.getRecipeByPreference(
                  recipeName,
                  preference,
                  availableIngredients: ingredientNames,
                );
                
                if (recipeDetails.isNotEmpty) {
                  _splashRecipeCache[recipeName] = recipeDetails;
                  preloadedRecipes++;
                  
                  if (kDebugMode) {
                    print('✅ [Smart Splash] Preloaded preference recipe: $recipeName ($preference)');
                    print('📦 [Smart Splash] Recipe keys: ${recipeDetails.keys.toList()}');
                    print('🖼️ [Smart Splash] Recipe image: ${recipeDetails['image_url']?.toString().substring(0, 50) ?? 'No image'}...');
                  }
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [Smart Splash] Error preloading preference $preference: $e');
            }
          }
        }
      }

      stopwatch.stop();
      
      if (kDebugMode) {
        print('✅ [Smart Splash] Smart preloading completed in ${stopwatch.elapsedMilliseconds}ms');
        print('📊 [Smart Splash] Preloaded recipes: $preloadedRecipes');
        print('🥘 [Smart Splash] Preloaded ingredients: $preloadedIngredients');
        print('🖼️ [Smart Splash] Cached images: $cachedImages');
        print('💾 [Smart Splash] Memory cache size: ${_splashRecipeCache.length + _splashIngredientCache.length}');
      }

      return {
        'success': true,
        'preloadedRecipes': preloadedRecipes,
        'preloadedIngredients': preloadedIngredients,
        'cachedImages': cachedImages,
        'totalTime': stopwatch.elapsedMilliseconds,
        'cacheSize': _splashRecipeCache.length + _splashIngredientCache.length,
      };

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Smart Splash] Smart preloading failed: $e');
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

  /// Generate sample recipe names for different cooking preferences
  static List<String> _generateSampleRecipesForPreference(String preference) {
    switch (preference.toLowerCase()) {
      case 'italian':
        return ['Pasta Carbonara', 'Margherita Pizza', 'Tiramisu'];
      case 'indian':
        return ['Butter Chicken', 'Palak Paneer', 'Biryani'];
      case 'chinese':
        return ['Fried Rice', 'Sweet and Sour Pork', 'Dumplings'];
      case 'mexican':
        return ['Tacos', 'Guacamole', 'Enchiladas'];
      case 'thai':
        return ['Pad Thai', 'Tom Yum Soup', 'Green Curry'];
      default:
        return ['Classic Pasta', 'Grilled Chicken', 'Vegetable Stir Fry'];
    }
  }

  /// Get preloaded recipe from memory cache
  static Map<String, dynamic>? getPreloadedRecipe(String recipeName) {
    final normalizedName = recipeName.toLowerCase().trim();
    return _splashRecipeCache[normalizedName];
  }

  /// Get preloaded ingredient from memory cache
  static Map<String, dynamic>? getPreloadedIngredient(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return _splashIngredientCache[normalizedName];
  }

  /// Check if recipe is preloaded
  static bool isRecipePreloaded(String recipeName) {
    final normalizedName = recipeName.toLowerCase().trim();
    return _splashRecipeCache.containsKey(normalizedName);
  }

  /// Check if ingredient is preloaded
  static bool isIngredientPreloaded(String ingredientName) {
    final normalizedName = ingredientName.toLowerCase().trim();
    return _splashIngredientCache.containsKey(normalizedName);
  }

  /// Get all preloaded recipes
  static Map<String, Map<String, dynamic>> getAllPreloadedRecipes() {
    return Map.from(_splashRecipeCache);
  }

  /// Get all preloaded ingredients
  static Map<String, Map<String, dynamic>> getAllPreloadedIngredients() {
    return Map.from(_splashIngredientCache);
  }

  /// Get access to splash recipe cache (for state persistence)
  static Map<String, Map<String, dynamic>> get splashRecipeCache => _splashRecipeCache;

  /// Get access to splash ingredient cache (for state persistence)
  static Map<String, Map<String, dynamic>> get splashIngredientCache => _splashIngredientCache;

  /// Clear memory cache
  static void clearMemoryCache() {
    _splashRecipeCache.clear();
    _splashIngredientCache.clear();
    if (kDebugMode) {
      print('🗑️ [Smart Splash] Memory cache cleared');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'service': 'Smart Splash Recipe Cache Service',
      'workflow': 'MongoDB-first with smart preloading',
      'memory_cache_recipes': _splashRecipeCache.length,
      'memory_cache_ingredients': _splashIngredientCache.length,
      'total_cached_items': _splashRecipeCache.length + _splashIngredientCache.length,
    };
  }

  /// Sync preloaded data to MongoDB for persistence
  static Future<void> syncToMongoDB() async {
    if (kDebugMode) {
      print('🔄 [Smart Splash] Syncing preloaded data to MongoDB...');
    }

    try {
      // Sync recipes to MongoDB
      for (final entry in _splashRecipeCache.entries) {
        final recipeName = entry.key;
        final recipeData = entry.value;
        
        // Store recipe in MongoDB using enhanced service
        await EnhancedRecipeDetailService.fetchRecipeDetailsWithIngredientCaching(recipeName);
      }

      // Sync ingredients to MongoDB
      for (final entry in _splashIngredientCache.entries) {
        final ingredientName = entry.key;
        final ingredientData = entry.value;
        final imageUrl = ingredientData['image_url'] as String;
        
        // Store ingredient in MongoDB using enhanced service
        await EnhancedIngredientImageService.getIngredientImage(ingredientName, imageUrl: imageUrl);
      }

      if (kDebugMode) {
        print('✅ [Smart Splash] Sync to MongoDB completed');
        print('📦 [Smart Splash] Synced recipes: ${_splashRecipeCache.length}');
        print('🥘 [Smart Splash] Synced ingredients: ${_splashIngredientCache.length}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Smart Splash] Sync to MongoDB failed: $e');
      }
    }
  }
}
