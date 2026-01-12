import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'recipe_detail_service.dart';
import 'mongo_ingredient_service.dart';
import 'enhanced_ingredient_image_service.dart';
import 'enhanced_recipe_image_service.dart';

class EnhancedRecipeDetailService {
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// Enhanced recipe details fetch with MongoDB-first ingredient image caching
  static Future<Map<String, dynamic>> fetchRecipeDetailsWithIngredientCaching(String recipeName) async {
    if (kDebugMode) {
      print('🔍 [Enhanced Recipe] Fetching recipe details with ingredient caching: $recipeName');
    }

    try {
      // Get recipe details using existing service
      final recipeDetails = await RecipeDetailService.fetchRecipeDetails(recipeName);
      
      // Process and cache ingredient images
      await _processAndCacheIngredientImages(recipeDetails);
      
      // Cache recipe image using enhanced service
      await _cacheRecipeImage(recipeName, recipeDetails);
      
      return recipeDetails;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error fetching recipe details: $e');
      }
      rethrow;
    }
  }

  /// Cache recipe image from recipe details using enhanced MongoDB-first workflow
  static Future<void> _cacheRecipeImage(String recipeName, Map<String, dynamic> recipeDetails) async {
    try {
      if (kDebugMode) {
        print('🔄 [Enhanced Recipe] Starting recipe image caching for: $recipeName');
      }
      
      // Extract recipe image URL from multiple possible fields
      final imageUrl = recipeDetails['image_url']?.toString() ?? 
                     recipeDetails['imageUrl']?.toString() ?? 
                     recipeDetails['image']?.toString() ?? 
                     recipeDetails['recipe_image_url']?.toString() ?? '';
      
      if (imageUrl.isNotEmpty) {
        // Use enhanced recipe image service to cache the recipe image
        await EnhancedRecipeImageService.getRecipeImage(recipeName, imageUrl: imageUrl);
        
        if (kDebugMode) {
          print('✅ [Enhanced Recipe] Cached recipe image: $recipeName -> $imageUrl');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [Enhanced Recipe] No image URL found for recipe: $recipeName');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error caching recipe image: $e');
      }
    }
  }

  /// Process ingredients from recipe details and cache their images in MongoDB
  static Future<void> _processAndCacheIngredientImages(Map<String, dynamic> recipeDetails) async {
    try {
      // Extract ingredients from different possible locations
      final List<Map<String, dynamic>> allIngredients = [];
      
      // 1. Check main ingredients list
      if (recipeDetails['ingredients'] != null) {
        final ingredients = recipeDetails['ingredients'] as List;
        for (final ingredient in ingredients) {
          if (ingredient is Map) {
            allIngredients.add({
              'name': _extractIngredientName(ingredient),
              'image_url': ingredient['image_url']?.toString() ?? '',
              'source': 'main_ingredients'
            });
          }
        }
      }

      // 2. Check cooking steps for ingredients_used
      if (recipeDetails['cooking_steps'] != null) {
        final cookingSteps = recipeDetails['cooking_steps'] as List;
        for (final step in cookingSteps) {
          if (step is Map && step['ingredients_used'] != null) {
            final stepIngredients = step['ingredients_used'] as List;
            for (final ingredient in stepIngredients) {
              if (ingredient is Map) {
                allIngredients.add({
                  'name': _extractIngredientName(ingredient),
                  'image_url': ingredient['image_url']?.toString() ?? '',
                  'source': 'cooking_steps'
                });
              }
            }
          }
        }
      }

      // 3. Check needed_ingredients list
      if (recipeDetails['needed_ingredients'] != null) {
        final neededIngredients = recipeDetails['needed_ingredients'] as List;
        for (final ingredient in neededIngredients) {
          if (ingredient is String) {
            allIngredients.add({
              'name': ingredient,
              'image_url': '',
              'source': 'needed_ingredients'
            });
          } else if (ingredient is Map) {
            allIngredients.add({
              'name': _extractIngredientName(ingredient),
              'image_url': ingredient['image_url']?.toString() ?? '',
              'source': 'needed_ingredients'
            });
          }
        }
      }

      if (kDebugMode) {
        print('🔍 [Enhanced Recipe] Found ${allIngredients.length} ingredients to process');
        for (final ingredient in allIngredients) {
          print('  - ${ingredient['name']} (${ingredient['source']})');
        }
      }

      // Process each ingredient for MongoDB caching
      for (final ingredientData in allIngredients) {
        await _cacheIngredientImageInMongoDB(ingredientData);
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error processing ingredient images: $e');
      }
    }
  }

  /// Extract ingredient name from various data structures
  static String _extractIngredientName(dynamic ingredient) {
    if (ingredient is Map) {
      return (ingredient['name'] ?? 
              ingredient['item'] ?? 
              ingredient['ingredient'] ?? 
              'Unknown').toString().trim();
    }
    return ingredient.toString().trim();
  }

  /// Cache individual ingredient image in MongoDB using enhanced service
  static Future<void> _cacheIngredientImageInMongoDB(Map<String, dynamic> ingredientData) async {
    try {
      final ingredientName = ingredientData['name'] as String;
      final imageUrl = ingredientData['image_url'] as String;
      final source = ingredientData['source'] as String;

      if (kDebugMode) {
        print('🔄 [Enhanced Recipe] Processing ingredient: $ingredientName from $source');
      }

      // Use enhanced ingredient image service which already implements MongoDB-first workflow
      final cachedImageUrl = await EnhancedIngredientImageService.getIngredientImage(
        ingredientName, 
        imageUrl: imageUrl.isNotEmpty ? imageUrl : null
      );

      if (kDebugMode) {
        if (cachedImageUrl != null) {
          print('✅ [Enhanced Recipe] Cached ingredient image: $ingredientName -> $cachedImageUrl');
        } else {
          print('⚠️ [Enhanced Recipe] No image cached for: $ingredientName');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error caching ingredient ${ingredientData['name']}: $e');
      }
    }
  }

  /// Batch process multiple recipes for ingredient caching
  static Future<void> batchCacheRecipeIngredients(List<String> recipeNames) async {
    if (kDebugMode) {
      print('🔄 [Enhanced Recipe] Batch processing ${recipeNames.length} recipes for ingredient caching');
    }

    for (final recipeName in recipeNames) {
      try {
        await fetchRecipeDetailsWithIngredientCaching(recipeName);
      } catch (e) {
        if (kDebugMode) {
          print('❌ [Enhanced Recipe] Error processing recipe $recipeName: $e');
        }
      }
    }

    if (kDebugMode) {
      print('✅ [Enhanced Recipe] Batch processing completed');
    }
  }

  /// Get statistics about ingredient caching
  static Future<Map<String, dynamic>> getIngredientCachingStats() async {
    try {
      // This would require additional MongoDB endpoints for detailed stats
      return {
        'service': 'Enhanced Recipe Detail Service',
        'workflow': 'MongoDB-first ingredient image caching',
        'features': [
          'Automatic ingredient extraction from recipes',
          'MongoDB-first image caching',
          'Batch processing support',
          'Multiple ingredient source support'
        ]
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error getting stats: $e');
      }
      return {};
    }
  }
}
