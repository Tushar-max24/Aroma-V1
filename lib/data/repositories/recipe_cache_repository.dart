// lib/data/repositories/recipe_cache_repository.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/recipe_cache_model.dart';
import '../services/cache_database_service.dart';
import '../services/gemini_recipe_service.dart';
import '../services/preference_api_service.dart';

class RecipeCacheRepository {
  static const Duration _cacheExpiration = Duration(hours: 24);

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

  static Future<GeneratedRecipeCache?> getCachedGeneratedRecipes(
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> ingredients,
  ) async {
    try {
      final preferenceHash = _generatePreferenceHash(preferences, ingredients);
      final cached = await CacheDatabaseService.getGeneratedRecipes(preferenceHash);
      
      if (cached != null) {
        // Check if cache is still valid
        if (DateTime.now().difference(cached.cachedAt) < _cacheExpiration) {
          print('✅ Generated recipes loaded from cache');
          return cached;
        } else {
          // Cache expired, remove it
          final db = await CacheDatabaseService.database;
          await db.delete(
            CacheDatabaseService.generatedRecipeTable,
            where: 'preference_hash = ?',
            whereArgs: [preferenceHash],
          );
        }
      }
    } catch (e) {
      print('Error getting cached generated recipes: $e');
    }
    return null;
  }

  static Future<GeneratedRecipeCache> getGeneratedRecipes(
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> ingredients,
  ) async {
    // Try to get from cache first
    final cachedData = await getCachedGeneratedRecipes(preferences, ingredients);
    if (cachedData != null) {
      print('✅ Generated recipes loaded from cache (${cachedData.recipes.length} recipes)');
      return cachedData;
    }

    // Fetch from backend API
    try {
      print('🔄 Fetching generated recipes from backend');
      final freshData = await PreferenceApiService.generateRecipes(ingredients, preferences);
      
      // Extract recipes and cuisine
      final recipes = List<Map<String, dynamic>>.from(freshData['data']?['Recipes'] ?? []);
      final cuisine = preferences['cuisine'] ?? '';
      
      print('📋 Backend returned ${recipes.length} recipes');
      
      // Create image cache map
      final Map<String, String> recipeImages = {};
      
      // Cache the fresh data
      final cache = GeneratedRecipeCache(
        preferenceHash: _generatePreferenceHash(preferences, ingredients),
        recipes: recipes,
        recipeImages: recipeImages,
        cuisine: cuisine,
        cachedAt: DateTime.now(),
      );
      
      await CacheDatabaseService.cacheGeneratedRecipes(cache);
      print('✅ Generated recipes cached successfully (${recipes.length} recipes)');
      
      return cache;
    } catch (e) {
      print('❌ Error fetching generated recipes: $e');
      rethrow;
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
}
