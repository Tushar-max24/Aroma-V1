import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RecipeGenerationService {
  static const String _baseUrl = "http://3.108.110.151:5001";
  
  // Generate recipes using the new API
  Future<List<Map<String, dynamic>>> generateRecipes(Map<String, dynamic> preferences) async {
    try {
      debugPrint("🚀 [RecipeService] Starting recipe generation at: ${DateTime.now().millisecondsSinceEpoch}");
      
      final response = await http.post(
        Uri.parse("$_baseUrl/generate-recipes"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(preferences),
      );
      
      debugPrint("📡 [RecipeService] API response received at: ${DateTime.now().millisecondsSinceEpoch}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Handle weekly recipe format: {"Days": [{"Date": "...", "Meals": [...]}]}
        if (responseData.containsKey('Days') && responseData['Days'] is List) {
          final List<dynamic> days = responseData['Days'];
          final List<Map<String, dynamic>> allMeals = [];
          
          for (final day in days) {
            if (day is Map<String, dynamic> && day.containsKey('Meals') && day['Meals'] is List) {
              final List<dynamic> meals = day['Meals'];
              for (final meal in meals) {
                if (meal is Map<String, dynamic>) {
                  // Add date info to meal for filtering
                  final enrichedMeal = Map<String, dynamic>.from(meal);
                  enrichedMeal['Date'] = day['Date']?.toString() ?? '';
                  enrichedMeal['image_url'] = '';
                  enrichedMeal['image_generated'] = false;
                  
                  // Preserve cuisine preference from the original request
                  final cuisinePreference = preferences['Cuisine_Preference']?.toString();
                  if (cuisinePreference != null && cuisinePreference.isNotEmpty) {
                    enrichedMeal['Cuisine_Preference'] = cuisinePreference;
                    enrichedMeal['Cuisine'] = cuisinePreference;
                    enrichedMeal['cuisine'] = cuisinePreference;
                    debugPrint("🍽️ [RecipeService] Added cuisine to meal: $cuisinePreference");
                  }
                  
                  allMeals.add(enrichedMeal);
                }
              }
            }
          }
          
          debugPrint("✅ [RecipeService] Generated ${allMeals.length} meals from ${days.length} days");
          
          // Start background image generation for each meal
          _generateImagesInBackground(allMeals);
          
          return allMeals;
        }
        // Handle regular recipe format: {"recipes": [...]}
        else if (responseData.containsKey('recipes') && responseData['recipes'] is List) {
          final List<dynamic> recipes = responseData['recipes'];
          debugPrint("✅ [RecipeService] Generated ${recipes.length} recipes");
          
          // Convert recipes to Map<String, dynamic> and add placeholder images
          final List<Map<String, dynamic>> enrichedRecipes = recipes.map((recipe) {
            if (recipe is Map<String, dynamic>) {
              // Add placeholder image URL initially
              final enrichedRecipe = Map<String, dynamic>.from(recipe);
              enrichedRecipe['image_url'] = ''; // Start with empty image
              enrichedRecipe['image_generated'] = false; // Track if image is generated
              
              // Preserve cuisine preference from the original request
              final cuisinePreference = preferences['Cuisine_Preference']?.toString();
              if (cuisinePreference != null && cuisinePreference.isNotEmpty) {
                enrichedRecipe['Cuisine_Preference'] = cuisinePreference;
                enrichedRecipe['Cuisine'] = cuisinePreference;
                enrichedRecipe['cuisine'] = cuisinePreference;
                debugPrint("🍽️ [RecipeService] Added cuisine to recipe: $cuisinePreference");
              }
              
              return enrichedRecipe;
            }
            return <String, dynamic>{};
          }).where((recipe) => recipe.isNotEmpty).toList();
          
          // Start background image generation for each recipe
          _generateImagesInBackground(enrichedRecipes);
          
          return enrichedRecipes;
        }
      }
      
      debugPrint("❌ [RecipeService] API Error: ${response.statusCode} - ${response.body}");
      return [];
    } catch (e) {
      debugPrint("❌ [RecipeService] Exception: $e");
      return [];
    }
  }
  
  // Generate images in background without blocking UI using unified image API
  Future<void> _generateImagesInBackground(List<Map<String, dynamic>> recipes) async {
    for (int i = 0; i < recipes.length; i++) {
      final recipe = recipes[i];
      
      // Skip if recipe already has a valid image
      if (recipe.containsKey('image_url') && 
          recipe['image_url'] != null && 
          recipe['image_url'].toString().isNotEmpty &&
          !recipe['image_url'].toString().contains('pexels.com')) {
        debugPrint("⏭️ [RecipeService] Skipping ${_getRecipeName(recipe)} - already has image");
        continue;
      }
      
      try {
        // Get recipe name for image generation
        final recipeName = _getRecipeName(recipe);
        debugPrint("🖼️ [RecipeService] Starting image generation for: $recipeName");
        
        final response = await http.post(
          Uri.parse("$_baseUrl/generate-image"),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'dish_name': recipeName, // Use exact format you specified
          }),
        ).timeout(const Duration(seconds: 30)); // Add timeout
        
        debugPrint("📡 [RecipeService] Image API response status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> imageData = jsonDecode(response.body);
          debugPrint("📦 [RecipeService] Image API response: ${imageData.keys.toList()}");
          debugPrint("📄 [RecipeService] Full response body: ${response.body}");
          
          String? imageUrl;
          
          // Handle different response formats
          if (imageData.containsKey('image_url')) {
            imageUrl = imageData['image_url'].toString();
          } else if (imageData.containsKey('results') && imageData['results'] is Map) {
            final results = imageData['results'] as Map<String, dynamic>;
            
            // Check if results has recipe name as a key (new format)
            if (results.containsKey(recipeName)) {
              final recipeData = results[recipeName] as Map<String, dynamic>;
              if (recipeData.containsKey('image_url')) {
                imageUrl = recipeData['image_url'].toString();
              } else if (recipeData.containsKey('url')) {
                imageUrl = recipeData['url'].toString();
              } else if (recipeData.containsKey('image')) {
                imageUrl = recipeData['image'].toString();
              }
            }
            // Check direct fields in results (old format)
            else if (results.containsKey('image_url')) {
              imageUrl = results['image_url'].toString();
            } else if (results.containsKey('url')) {
              imageUrl = results['url'].toString();
            } else if (results.containsKey('image')) {
              imageUrl = results['image'].toString();
            }
          } else if (imageData.containsKey('url')) {
            imageUrl = imageData['url'].toString();
          } else if (imageData.containsKey('image')) {
            imageUrl = imageData['image'].toString();
          }
          
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint("🔗 [RecipeService] Raw image URL: $imageUrl");
            
            // Ensure HTTPS for S3 URLs
            if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
              debugPrint("🔒 [RecipeService] Converted S3 URL to HTTPS: $imageUrl");
            }
            
            // Update recipe with generated image
            recipes[i]['image_url'] = imageUrl;
            recipes[i]['image_generated'] = true;
            debugPrint("✅ [RecipeService] Image generated for: $recipeName");
            
            // Add delay between requests to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            debugPrint("❌ [RecipeService] No image URL found in response for: $recipeName");
            debugPrint("📄 [RecipeService] Available keys: ${imageData.keys.toList()}");
          }
        } else {
          debugPrint("❌ [RecipeService] Image generation failed for: $recipeName - ${response.statusCode}");
          debugPrint("📄 [RecipeService] Error response: ${response.body}");
        }
      } catch (e) {
        final recipeName = _getRecipeName(recipe);
        debugPrint("❌ [RecipeService] Image generation exception for: $recipeName - $e");
        
        // Continue with next recipe even if current one fails
        continue;
      }
    }
    
    debugPrint("🏁 [RecipeService] Image generation completed for ${recipes.length} recipes");
  }
  
  // Helper method to extract recipe name from different recipe formats
  String _getRecipeName(Map<String, dynamic> recipe) {
    // Try different possible name fields
    final nameFields = ['Recipe Name', 'recipe_name', 'name', 'title', 'dish_name'];
    
    for (final field in nameFields) {
      if (recipe.containsKey(field) && recipe[field] != null) {
        final name = recipe[field].toString();
        if (name.isNotEmpty) {
          return name;
        }
      }
    }
    
    // Fallback to a generic name
    return 'Recipe';
  }
  
  // Generate image for a single recipe using the unified image API
  Future<String?> generateImageForRecipe(Map<String, dynamic> recipe) async {
    try {
      final recipeName = recipe['Recipe Name'] ?? 'Recipe';
      debugPrint("🖼️ [RecipeService] Generating image for: $recipeName");
      
      final response = await http.post(
        Uri.parse("$_baseUrl/generate-image"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'dish_name': recipeName,
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> imageData = jsonDecode(response.body);
        if (imageData.containsKey('image_url')) {
          String imageUrl = imageData['image_url'].toString();
          
          // Ensure HTTPS for S3 URLs
          if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
            imageUrl = imageUrl.replaceFirst('http://', 'https://');
            debugPrint("🔒 [RecipeService] Converted S3 URL to HTTPS: $imageUrl");
          }
          
          debugPrint("✅ [RecipeService] Image generated: $imageUrl");
          return imageUrl;
        }
      }
      
      debugPrint("❌ [RecipeService] Image generation failed: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("❌ [RecipeService] Image generation exception: $e");
      return null;
    }
  }
}
