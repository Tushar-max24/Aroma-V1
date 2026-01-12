import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/home_recipe_service.dart';
import '../data/models/recipe_model.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRecipeService _service = HomeRecipeService();

  bool isLoading = false;
  String? error;

  /// 🔥 UI EXPECTS RecipeModel
  List<RecipeModel> recipes = [];

  // Fallback recipes in case of API failure
  final List<RecipeModel> _fallbackRecipes = [
    RecipeModel(
      id: "f1",
      title: "Masala Dosa",
      cuisine: "Indian",
      cookTime: '15',
      image: "https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg",
    ),
    RecipeModel(
      id: "f2",
      title: "Vegetable Upma",
      cuisine: "Indian",
      cookTime: '20',
      image: "https://images.pexels.com/photos/5848490/pexels-photo-5848490.jpeg",
    ),
  ];


  // NORMALIZE API RESPONSE → RecipeModel
  List<RecipeModel> _normalizeRecipes(List<dynamic> apiData) {
  return apiData.map<RecipeModel>((item) {
    debugPrint(' Recipe item keys: ${item.keys.toList()}');
    debugPrint(' Recipe item: $item');
    
    final Map<String, dynamic> imageObj =
        Map<String, dynamic>.from(item["Image"] ?? {});

    // Parse cooking time - try multiple possible field names and formats
    String rawTime = "0";
    final possibleTimeFields = [
      "Cooking Time", "cooking_time", "total_time", "totalTime", 
      "cook_time", "prep_time", "preparation_time", "time"
    ];
    
    for (final field in possibleTimeFields) {
      if (item[field] != null && item[field].toString().isNotEmpty) {
        rawTime = item[field].toString();
        debugPrint(' Found time in field "$field": $rawTime');
        break;
      }
    }
    
    // Extract numeric value from various formats like "15 min", "15-20 min", "15-30", etc.
    String cookTimeStr = rawTime;
    
    // Try to extract the first number found
    final numberMatch = RegExp(r'\d+').firstMatch(rawTime);
    if (numberMatch != null) {
      cookTimeStr = numberMatch.group(0) ?? "0";
    } else {
      // If no numbers found, try to parse directly
      cookTimeStr = rawTime.replaceAll(RegExp(r'[^0-9]'), '');
    }
    
    final cookTime = int.tryParse(cookTimeStr) ?? 0;
    debugPrint(' Parsed cookTime: $cookTime from raw: "$rawTime"');

    // Extract ingredients list from backend data
    List<String> ingredientStrings = [];
    if (item["Ingredients Needed"] != null && item["Ingredients Needed"] is Map) {
      ingredientStrings = (item["Ingredients Needed"] as Map)
          .entries
          .map((entry) => "${entry.key}: ${entry.value}")
          .toList();
    } else if (item["ingredients"] != null) {
      ingredientStrings = (item["ingredients"] as List)
          .map((ing) => ing['item']?.toString() ?? ing.toString())
          .toList();
    }

    // Extract instructions from backend data
    List<String> instructionStrings = [];
    if (item["Recipe Steps"] != null && item["Recipe Steps"] is List) {
      instructionStrings = (item["Recipe Steps"] as List)
          .map((step) => step.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (item["cooking_steps"] != null) {
      instructionStrings = (item["cooking_steps"] as List)
          .map((step) => step['instruction']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Try multiple possible field names for recipe title
    String recipeTitle = "Unknown Dish";
    if (item["recipe_name"] != null) {
      recipeTitle = item["recipe_name"].toString();
      debugPrint(' Found title in "recipe_name" field: $recipeTitle');
    } else if (item["Recipe Name"] != null) {
      recipeTitle = item["Recipe Name"].toString();
      debugPrint(' Found title in "Recipe Name" field: $recipeTitle');
    } else if (item["name"] != null) {
      recipeTitle = item["name"].toString();
      debugPrint(' Found title in "name" field: $recipeTitle');
    } else if (item["title"] != null) {
      recipeTitle = item["title"].toString();
      debugPrint(' Found title in "title" field: $recipeTitle');
    } else if (item["dish_name"] != null) {
      recipeTitle = item["dish_name"].toString();
      debugPrint(' Found title in "dish_name" field: $recipeTitle');
    } else if (imageObj["dish_name"] != null) {
      recipeTitle = imageObj["dish_name"].toString();
      debugPrint(' Found title in "Image.dish_name" field: $recipeTitle');
    } else if (imageObj["name"] != null) {
      recipeTitle = imageObj["name"].toString();
      debugPrint(' Found title in "Image.name" field: $recipeTitle');
    } else {
      debugPrint(' No title field found, using "Unknown Dish"');
    }

    return RecipeModel(
      id: recipeTitle.replaceAll(' ', '_'), // Use recipe title as ID
      title: recipeTitle,
      cuisine: item["cuisine"]?.toString() ?? "Indian",
      cookTime: cookTime.toString(),
      image: item["recipe_image_url"]?.toString() ??
          imageObj["image_url"]?.toString() ??
          "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg",
      isSaved: false,
      description: item["description"]?.toString() ?? "",
      servings: (item["servings"] as num?)?.toInt() ?? 1,
      calories: (item["nutrition"]?["calories"] as num?)?.toInt() ?? 0,
      ingredients: ingredientStrings,
      instructions: instructionStrings,
      fullRecipeData: Map<String, dynamic>.from(item), // Store complete backend data
    );
  }).toList();
}



  static const String _cachedRecipesKey = 'cached_recipes';
  
  HomeProvider() {
    // Load cached recipes first, then fetch fresh ones
    _loadCachedRecipes().then((_) => loadRecipes());
  }
  
  // Load recipes from cache
  Future<void> _loadCachedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cachedRecipesKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final cachedRecipes = jsonList.map((item) => 
          RecipeModel.fromJson(Map<String, dynamic>.from(item))
        ).toList();
        
        if (cachedRecipes.isNotEmpty) {
          recipes = cachedRecipes;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached recipes: $e');
    }
  }
  
  // Save recipes to cache
  Future<void> _saveRecipesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(recipes.map((r) => r.toJson()).toList());
      await prefs.setString(_cachedRecipesKey, jsonData);
    } catch (e) {
      debugPrint('Error saving recipes to cache: $e');
    }
  }
  
  // Clear cache (for testing or when needed)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedRecipesKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Generate recipe images in background using /generate-image API
  Future<void> _generateRecipeImagesInBackground(List<RecipeModel> recipes) async {
    const String imageApiUrl = 'http://3.108.110.151:5001/generate-image';
    
    for (int i = 0; i < recipes.length; i++) {
      final recipe = recipes[i];
      
      // Skip if recipe already has a valid image (not fallback)
      if (recipe.image.isNotEmpty && 
          !recipe.image.contains('pexels.com') && 
          !recipe.image.contains('1640777')) {
        debugPrint("⏭️ [Home Provider] Skipping ${recipe.title} - already has image: ${recipe.image.substring(0, 50)}...");
        continue;
      }
      
      try {
        debugPrint("🖼️ [Home Provider] Starting image generation for: ${recipe.title}");
        
        final response = await http.post(
          Uri.parse(imageApiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'dish_name': recipe.title, // Use the exact format you specified
          }),
        ).timeout(const Duration(seconds: 30)); // Add timeout
        
        debugPrint("📡 [Home Provider] Image API response status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> imageData = jsonDecode(response.body);
          debugPrint("📦 [Home Provider] Image API response: ${imageData.keys.toList()}");
          debugPrint("📄 [Home Provider] Full response body: ${response.body}");
          
          String? imageUrl;
          
          // Handle different response formats
          if (imageData.containsKey('image_url')) {
            imageUrl = imageData['image_url'].toString();
          } else if (imageData.containsKey('results') && imageData['results'] is Map) {
            final results = imageData['results'] as Map<String, dynamic>;
            
            // Check if results has the recipe name as a key (new format)
            if (results.containsKey(recipe.title)) {
              final recipeData = results[recipe.title] as Map<String, dynamic>;
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
            debugPrint("🔗 [Home Provider] Raw image URL: $imageUrl");
            
            // Ensure HTTPS for S3 URLs
            if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
              debugPrint("🔒 [Home Provider] Converted S3 URL to HTTPS: $imageUrl");
            }
            
            // Update recipe with generated image
            recipes[i] = recipe.copyWith(image: imageUrl);
            debugPrint("✅ [Home Provider] Image generated for: ${recipe.title}");
            
            // Notify listeners to update UI
            notifyListeners();
            
            // Add delay between requests to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            debugPrint("❌ [Home Provider] No image URL found in response for: ${recipe.title}");
            debugPrint("📄 [Home Provider] Available keys: ${imageData.keys.toList()}");
          }
        } else {
          debugPrint("❌ [Home Provider] Image generation failed for: ${recipe.title} - ${response.statusCode}");
          debugPrint("📄 [Home Provider] Error response: ${response.body}");
        }
      } catch (e) {
        debugPrint("❌ [Home Provider] Image generation exception for: ${recipe.title} - $e");
        
        // Continue with next recipe even if current one fails
        continue;
      }
    }
    
    debugPrint("🏁 [Home Provider] Image generation completed for ${recipes.length} recipes");
  }

  // Load recipes for Home screen
  Future<void> loadRecipes() async {
    try {
      // Don't show loading state to prevent UI flicker
      // We already have cached or fallback recipes showing
      
      final data = await _service.generateHomeRecipes();

      if (data.isNotEmpty) {
        final newRecipes = _normalizeRecipes(data);
        if (newRecipes.isNotEmpty) {
          recipes = newRecipes;
          // Save to cache
          await _saveRecipesToCache();
          notifyListeners();
          
          // Start background image generation for recipes without images
          _generateRecipeImagesInBackground(recipes);
        }
      }
    } catch (e) {
      // Silently handle errors, we already have cached or fallback recipes
      debugPrint(" Home API Error: $e");
      // If we don't have any recipes yet, use fallback
      if (recipes.isEmpty) {
        recipes = List.from(_fallbackRecipes);
        notifyListeners();
      }
    }
  }

  // Save / Unsave (IMMUTABLE SAFE)
  void toggleSaved(String recipeId) {
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index == -1) return;

    recipes[index] = recipes[index].copyWith(
      isSaved: !recipes[index].isSaved,
    );

    notifyListeners();
  }
}