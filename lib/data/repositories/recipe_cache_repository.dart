// lib/data/repositories/recipe_cache_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../models/recipe_cache_model.dart';
import '../services/cache_database_service.dart';
import '../services/gemini_recipe_service.dart';
import '../services/preference_api_service.dart';
import '../services/ingredient_image_service.dart';

class RecipeCacheRepository {
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  // Track preloading status to avoid duplicate requests
  static final Set<String> _preloadingRecipes = {};

  // Recipe Details Caching
  static Future<Map<String, dynamic>?> getCachedRecipeDetails(String recipeName) async {
    try {
      final cached = await CacheDatabaseService.getRecipeDetail(recipeName);
      
      if (cached != null) {
        // Check if cache is still valid
        if (DateTime.now().difference(cached.cachedAt) < _cacheExpiration) {
          return cached.toGeminiFormat();
        } else {
          // Cache expired, remove it
          final db = await CacheDatabaseService.database;
          await db.delete(
            CacheDatabaseService.recipeDetailTable,
            where: 'recipe_name = ?',
            whereArgs: [recipeName],
          );
        }
      }
    } catch (e) {
      print('Error getting cached recipe details: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> getRecipeDetails(String recipeName) async {
    // Try to get from cache first
    final cachedData = await getCachedRecipeDetails(recipeName);
    if (cachedData != null) {
      print('✅ Recipe details loaded from cache: $recipeName');
      return cachedData;
    }

    // Fetch from Gemini API
    try {
      print('🔄 Fetching recipe details from Gemini: $recipeName');
      final freshData = await GeminiRecipeService.fetchRecipeData(recipeName);
      
      // Cache the fresh data
      final cache = RecipeDetailCache(
        recipeName: recipeName,
        description: freshData['description'] ?? '',
        nutrition: freshData['nutrition'] ?? {},
        cookware: List<String>.from(freshData['cookware'] ?? []),
        preparationSteps: List<Map<String, dynamic>>.from(freshData['steps'] ?? []),
        cachedAt: DateTime.now(),
      );
      
      await CacheDatabaseService.cacheRecipeDetail(cache);
      print('✅ Recipe details cached: $recipeName');
      
      return freshData;
    } catch (e) {
      print('❌ Error fetching recipe details: $e');
      rethrow;
    }
  }

  // Cooking Steps Caching
  static Future<List<Map<String, dynamic>>> getCachedCookingSteps(String recipeName) async {
    try {
      final cachedSteps = await CacheDatabaseService.getCookingSteps(recipeName);
      
      if (cachedSteps.isNotEmpty) {
        // Check if cache is still valid (using the most recent step's timestamp)
        final mostRecentStep = cachedSteps.reduce((a, b) => 
          a.cachedAt.isAfter(b.cachedAt) ? a : b);
        
        if (DateTime.now().difference(mostRecentStep.cachedAt) < _cacheExpiration) {
          return cachedSteps.map((step) => step.toStepFormat()).toList();
        } else {
          // Cache expired, remove it
          final db = await CacheDatabaseService.database;
          await db.delete(
            CacheDatabaseService.cookingStepTable,
            where: 'recipe_name = ?',
            whereArgs: [recipeName],
          );
        }
      }
    } catch (e) {
      print('Error getting cached cooking steps: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getCookingSteps(String recipeName) async {
    // Try to get from cache first
    final cachedSteps = await getCachedCookingSteps(recipeName);
    if (cachedSteps.isNotEmpty) {
      print('✅ Cooking steps loaded from cache: $recipeName');
      return cachedSteps;
    }

    // Get from recipe details (which handles caching)
    try {
      final recipeData = await getRecipeDetails(recipeName);
      final steps = List<Map<String, dynamic>>.from(recipeData['steps'] ?? []);
      
      // Cache individual steps
      final stepCaches = steps.asMap().entries.map((entry) {
        final stepNumber = entry.key + 1;
        final step = entry.value;
        
        return CookingStepCache(
          recipeName: recipeName,
          stepNumber: stepNumber,
          instruction: step['instruction'] ?? '',
          tips: List<String>.from(step['tips'] ?? []),
          ingredients: List<Map<String, dynamic>>.from(step['ingredients'] ?? []),
          cachedAt: DateTime.now(),
        );
      }).toList();
      
      await CacheDatabaseService.cacheCookingSteps(stepCaches);
      print('✅ Cooking steps cached: $recipeName');
      
      return steps;
    } catch (e) {
      print('❌ Error fetching cooking steps: $e');
      rethrow;
    }
  }

  // Generated Recipes Caching
  static String _generatePreferenceHash(Map<String, dynamic> preferences, List<Map<String, dynamic>> ingredients) {
    final combined = {
      'preferences': preferences,
      'ingredients': ingredients.map((ing) => ing['item']).toList()..sort(),
    };
    final jsonString = jsonEncode(combined);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  static Future<GeneratedRecipeCache?> getGeneratedRecipes(
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> ingredients,
  ) async {
    // Bypass cache and directly fetch from backend API
    try {
      print('🔄 Bypassing cache - fetching directly from backend');
      final freshData = await PreferenceApiService.generateRecipes(ingredients, preferences);
      
      // Extract recipes and cuisine
      final recipes = List<Map<String, dynamic>>.from(freshData['data']?['Recipes'] ?? freshData['recipes'] ?? []);
      final cuisine = preferences['cuisine'] ?? '';
      
      print('📋 Backend returned ${recipes.length} recipes');
      
      // Return backend data directly without caching
      return GeneratedRecipeCache(
        preferenceHash: '', // Empty hash since we're not caching
        recipes: recipes,
        recipeImages: {},
        cuisine: cuisine,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error getting cached generated recipes: $e');
      debugPrint('❌ Database error details: ${e.toString()}');
      return null;
    }
  }

  // Image Caching for Generated Recipes
  static Future<String?> getCachedRecipeImage(String recipeName) async {
    try {
      // Get all generated recipe caches to find the image
      final db = await CacheDatabaseService.database;
      final maps = await db.query(CacheDatabaseService.generatedRecipeTable);
      
      for (final map in maps) {
        final recipeImages = Map<String, String>.from(
          jsonDecode(map['recipe_images']?.toString() ?? '{}')
        );
        if (recipeImages.containsKey(recipeName)) {
          return recipeImages[recipeName] as String?;
        }
      }
    } catch (e) {
      print('Error getting cached recipe image: $e');
    }
    return null;
  }

  static Future<void> cacheRecipeImage(String recipeName, String imageUrl) async {
    try {
      // Update all relevant caches with the new image
      final db = await CacheDatabaseService.database;
      final maps = await db.query(CacheDatabaseService.generatedRecipeTable);
      
      for (final map in maps) {
        final recipeImages = Map<String, String>.from(
          jsonDecode(map['recipe_images']?.toString() ?? '{}')
        );
        recipeImages[recipeName] = imageUrl;
        
        await db.update(
          CacheDatabaseService.generatedRecipeTable,
          {
            'recipe_images': jsonEncode(recipeImages),
          },
          where: 'id = ?',
          whereArgs: [map['id']],
        );
      }
      
      print('✅ Recipe image cached: $recipeName');
    } catch (e) {
      print('Error caching recipe image: $e');
    }
  }

  // Utility Methods
  static Future<void> clearAllCache() async {
    await CacheDatabaseService.clearCache();
    print('🗑️ All cache cleared');
  }

  static Future<void> clearExpiredCache() async {
    await CacheDatabaseService.clearExpiredCache();
    print('🗑️ Expired cache cleared');
  }

  // Preloading Methods
  static Future<void> preloadRecipeDetails(List<String> recipeNames) async {
    for (final recipeName in recipeNames) {
      // Skip if already being preloaded
      if (_preloadingRecipes.contains(recipeName)) {
        continue;
      }
      
      _preloadingRecipes.add(recipeName);
      
      try {
        // Check if already cached
        final cachedData = await getCachedRecipeDetails(recipeName);
        if (cachedData != null) {
          print('✅ Recipe details already cached: $recipeName');
          _preloadingRecipes.remove(recipeName);
          continue;
        }
        
        // Preload from Gemini API
        print('🔄 Preloading recipe details: $recipeName');
        await getRecipeDetails(recipeName);
        print('✅ Recipe details preloaded: $recipeName');
      } catch (e) {
        print('❌ Error preloading recipe details for $recipeName: $e');
      } finally {
        _preloadingRecipes.remove(recipeName);
      }
    }
  }

  static Future<void> preloadCookingSteps(List<String> recipeNames) async {
    for (final recipeName in recipeNames) {
      // Skip if already being preloaded
      if (_preloadingRecipes.contains(recipeName)) {
        continue;
      }
      
      _preloadingRecipes.add(recipeName);
      
      try {
        // Check if already cached
        final cachedSteps = await getCachedCookingSteps(recipeName);
        List<Map<String, dynamic>> steps;
        
        if (cachedSteps.isNotEmpty) {
          print('✅ Cooking steps already cached: $recipeName');
          steps = cachedSteps;
        } else {
          // Preload from Gemini API
          print('🔄 Preloading cooking steps: $recipeName');
          steps = await getCookingSteps(recipeName);
          print('✅ Cooking steps preloaded: $recipeName');
        }
        
        // Extract and preload ingredient images from cooking steps
        // This ensures ingredient images are preloaded even if steps were already cached
        await _preloadIngredientImagesFromSteps(steps, recipeName);
      } catch (e) {
        print('❌ Error preloading cooking steps for $recipeName: $e');
      } finally {
        _preloadingRecipes.remove(recipeName);
      }
    }
  }

  /// Extract ingredients from cooking steps and preload their images
  static Future<void> _preloadIngredientImagesFromSteps(
    List<Map<String, dynamic>> steps, 
    String recipeName
  ) async {
    try {
      final Set<String> ingredientNames = {};
      
      // Extract all ingredient names from all steps
      for (final step in steps) {
        final ingredients = step['ingredients'] as List? ?? [];
        for (final ingredient in ingredients) {
          if (ingredient is Map<String, dynamic>) {
            final itemName = ingredient['item']?.toString();
            if (itemName != null && itemName.isNotEmpty) {
              ingredientNames.add(itemName.trim());
            }
          }
        }
      }
      
      if (ingredientNames.isNotEmpty) {
        print('🖼️ Preloading ${ingredientNames.length} ingredient images for: $recipeName');
        print('📝 Ingredients: ${ingredientNames.take(10).join(', ')}${ingredientNames.length > 10 ? '...' : ''}');
        
        // Preload all ingredient images in parallel
        final futures = ingredientNames.map((ingredientName) async {
          try {
            await IngredientImageService.getIngredientImage(ingredientName);
            print('✅ Preloaded ingredient image: $ingredientName');
          } catch (e) {
            print('❌ Failed to preload ingredient image: $ingredientName ($e)');
          }
        }).toList();
        
        await Future.wait(futures);
        print('✅ Completed ingredient image preloading for: $recipeName');
      }
    } catch (e) {
      print('❌ Error preloading ingredient images for $recipeName: $e');
    }
  }

  static Future<void> preloadRecipeData(List<String> recipeNames) async {
    print('🚀 Starting preload for ${recipeNames.length} recipes');
    
    // Preload recipe details and cooking steps in parallel
    await Future.wait([
      preloadRecipeDetails(recipeNames),
      preloadCookingSteps(recipeNames),
    ]);
    
    print('✅ Preload completed for ${recipeNames.length} recipes');
  }
}
