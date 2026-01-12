import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_recipe_service.dart';
import 'cache_database_service.dart';
import '../models/recipe_cache_model.dart';
import 'generate_recipe_service.dart';
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
      // Get today's date string (YYYY-MM-DD format)
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      print("📅 Checking for daily preferences for date: $dateString");
      
      // Check if we already have preferences for today
      final cachedDailyPrefs = await CacheDatabaseService.getDailyPreferences(dateString);
      
      if (cachedDailyPrefs != null) {
        print("✅ Using cached daily preferences");
        return cachedDailyPrefs['preferences'] as Map<String, dynamic>;
      }
      
      print("🎲 No cached preferences found for today, generating new ones");
      
      // Generate new preferences since we don't have them for today
      final preferences = await _generateNewPreferences();
      
      // Generate hash for new preferences
      final preferenceHash = _generatePreferenceHash(preferences);
      
      // Cache the daily preferences
      await CacheDatabaseService.cacheDailyPreferences(dateString, preferences, preferenceHash);
      print("💾 Cached daily preferences for today");
      
      return preferences;
    } catch (e) {
      print('❌ Error in _generateDynamicPreferences: $e');
      return _getDefaultPreferences();
    }
  }

  // Separate method to actually generate new preferences (called only when needed)
  Future<Map<String, dynamic>> _generateNewPreferences() async {
    try {
      // Get current date and time to create rotating combinations
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final hourOfDay = now.hour;
      
      // Create rotating combinations based on time
      final cuisines = ["North Indian", "South Indian", "Chinese", "Italian", "Continental", "Mexican", "Thai", "Japanese"];
      final dietaryOptions = ["Vegetarian", "Vegan", "Non-Vegetarian", "Gluten-Free", "None"];
      final mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"];
      final cookwareOptions = [["Gas Stove", "Pan"], ["Gas Stove", "Oven"], ["Microwave", "Pan"], ["Air Fryer", "Oven"]];
      final cookingTimes = ["< 15 min", "< 30 min", "< 45 min", "< 1 hour"];
      final servings = [1, 2, 3, 4];
      
      // Create rotating indices based on date and time
      final cuisineIndex = (dayOfYear + hourOfDay) % cuisines.length;
      final dietaryIndex = (dayOfYear ~/ 2 + hourOfDay ~/ 2) % dietaryOptions.length;
      final mealTypeIndex = (dayOfYear ~/ 3 + hourOfDay) % mealTypes.length;
      final cookwareIndex = (dayOfYear ~/ 4) % cookwareOptions.length;
      final timeIndex = (dayOfYear ~/ 5) % cookingTimes.length;
      final servingIndex = (dayOfYear ~/ 6) % servings.length;
      
      final selectedCuisine = cuisines[cuisineIndex];
      final selectedDietary = dietaryOptions[dietaryIndex];
      final selectedMealType = mealTypes[mealTypeIndex];
      final selectedCookware = cookwareOptions[cookwareIndex];
      final selectedTime = cookingTimes[timeIndex];
      final selectedServing = servings[servingIndex];
      
      // Generate diverse ingredients based on cuisine
      final ingredients = _generateIngredientsForCuisine(selectedCuisine);
      
      final preferences = {
        "Cuisine_Preference": selectedCuisine,
        "Dietary_Restrictions": selectedDietary,
        "Cookware_Available": selectedCookware,
        "Meal_Type": [selectedMealType],
        "Cooking_Time": selectedTime,
        "Serving": selectedServing.toString(),
        "Ingredients_Available": ingredients,
      };
      
      // Log the exact combination being used
      print("🎲 Generated Preference Combination:");
      print("   $selectedDietary + $selectedCuisine + $selectedMealType + ${selectedCookware.join(' + ')} + $selectedTime + $selectedServing servings");
      
      return preferences;
    } catch (e) {
      print('❌ Error generating preferences: $e');
      return _getDefaultPreferences();
    }
  }
  
  // Generate ingredients based on cuisine type
  List<Map<String, dynamic>> _generateIngredientsForCuisine(String cuisine) {
    final ingredientSets = {
      "North Indian": [
        {"item": "Rice", "quantity": "2", "metrics": "cups", "match%": 95},
        {"item": "Onion", "quantity": "2", "metrics": "pcs", "match%": 92},
        {"item": "Tomato", "quantity": "3", "metrics": "pcs", "match%": 88},
        {"item": "Ginger", "quantity": "1", "metrics": "inch", "match%": 85},
        {"item": "Garlic", "quantity": "4", "metrics": "cloves", "match%": 90},
      ],
      "South Indian": [
        {"item": "Rice", "quantity": "1.5", "metrics": "cups", "match%": 96},
        {"item": "Coconut", "quantity": "1", "metrics": "pc", "match%": 89},
        {"item": "Curry Leaves", "quantity": "10", "metrics": "leaves", "match%": 87},
        {"item": "Mustard Seeds", "quantity": "1", "metrics": "tsp", "match%": 93},
        {"item": "Lentils", "quantity": "1", "metrics": "cup", "match%": 91},
      ],
      "Chinese": [
        {"item": "Rice", "quantity": "2", "metrics": "cups", "match%": 94},
        {"item": "Soy Sauce", "quantity": "2", "metrics": "tbsp", "match%": 92},
        {"item": "Ginger", "quantity": "1", "metrics": "inch", "match%": 88},
        {"item": "Garlic", "quantity": "3", "metrics": "cloves", "match%": 90},
        {"item": "Spring Onions", "quantity": "2", "metrics": "pcs", "match%": 86},
      ],
      "Italian": [
        {"item": "Pasta", "quantity": "200", "metrics": "g", "match%": 95},
        {"item": "Tomato", "quantity": "4", "metrics": "pcs", "match%": 91},
        {"item": "Basil", "quantity": "10", "metrics": "leaves", "match%": 87},
        {"item": "Garlic", "quantity": "3", "metrics": "cloves", "match%": 93},
        {"item": "Olive Oil", "quantity": "2", "metrics": "tbsp", "match%": 89},
      ],
      "Continental": [
        {"item": "Potato", "quantity": "3", "metrics": "pcs", "match%": 94},
        {"item": "Butter", "quantity": "50", "metrics": "g", "match%": 90},
        {"item": "Cream", "quantity": "100", "metrics": "ml", "match%": 88},
        {"item": "Cheese", "quantity": "100", "metrics": "g", "match%": 92},
        {"item": "Herbs", "quantity": "2", "metrics": "tsp", "match%": 85},
      ],
      "Mexican": [
        {"item": "Tortilla", "quantity": "4", "metrics": "pcs", "match%": 93},
        {"item": "Beans", "quantity": "1", "metrics": "cup", "match%": 91},
        {"item": "Cheese", "quantity": "100", "metrics": "g", "match%": 89},
        {"item": "Tomato", "quantity": "2", "metrics": "pcs", "match%": 87},
        {"item": "Onion", "quantity": "1", "metrics": "pc", "match%": 90},
      ],
      "Thai": [
        {"item": "Rice", "quantity": "1.5", "metrics": "cups", "match%": 95},
        {"item": "Coconut Milk", "quantity": "200", "metrics": "ml", "match%": 90},
        {"item": "Lemongrass", "quantity": "1", "metrics": "stalk", "match%": 86},
        {"item": "Chili", "quantity": "2", "metrics": "pcs", "match%": 88},
        {"item": "Fish Sauce", "quantity": "1", "metrics": "tbsp", "match%": 84},
      ],
      "Japanese": [
        {"item": "Rice", "quantity": "2", "metrics": "cups", "match%": 96},
        {"item": "Soy Sauce", "quantity": "2", "metrics": "tbsp", "match%": 93},
        {"item": "Seaweed", "quantity": "5", "metrics": "sheets", "match%": 87},
        {"item": "Ginger", "quantity": "1", "metrics": "inch", "match%": 89},
        {"item": "Wasabi", "quantity": "1", "metrics": "tsp", "match%": 85},
      ],
    };
    
    // Return ingredients for the selected cuisine, fallback to North Indian
    return ingredientSets[cuisine] ?? ingredientSets["North Indian"]!;
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
      "Ingredients_Available": [
        {"item": "Potato", "quantity": "2", "metrics": "pcs", "match%": 94},
        {"item": "Rice", "quantity": "1", "metrics": "cup", "match%": 96},
        {"item": "Onion", "quantity": "1", "metrics": "pc", "match%": 92},
        {"item": "Tomato", "quantity": "2", "metrics": "pcs", "match%": 88},
      ],
    };
  }

  // Generate hash for caching
  String _generatePreferenceHash(Map<String, dynamic> preferences) {
    final prefString = jsonEncode(preferences);
    final bytes = utf8.encode(prefString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Load cached recipes as fallback when API is unavailable
  Future<List<dynamic>> _loadCachedRecipesAsFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString('cached_recipes');
      
      if (cachedData != null) {
        final List<dynamic> cachedRecipes = jsonDecode(cachedData);
        print('✅ Loaded ${cachedRecipes.length} cached recipes as fallback');
        return cachedRecipes;
      }
      
      print('⚠️ No cached recipes available');
      return [];
    } catch (e) {
      print('❌ Error loading cached recipes: $e');
      return [];
    }
  }

  // Generate images for recipes that don't have them
  Future<List<dynamic>> _generateRecipeImages(List<dynamic> recipes) async {
    print("🖼️ Generating images for ${recipes.length} recipes...");
    
    final recipeService = GenerateRecipeService();
    final List<Future<void>> imageGenerationTasks = [];
    
    for (int i = 0; i < recipes.length; i++) {
      final recipe = recipes[i] as Map<String, dynamic>;
      
      // Check if recipe already has an image
      if (recipe['recipe_image_url'] != null && recipe['recipe_image_url'].toString().isNotEmpty) {
        print("✅ Recipe ${recipe['recipe_name'] ?? recipe['Dish'] ?? 'Unknown'} already has image: ${recipe['recipe_image_url']}");
        continue;
      }
      
      // Extract recipe name
      final recipeName = recipe['recipe_name']?.toString() ?? 
                        recipe['Dish']?.toString() ?? 
                        'Unknown Recipe';
      
      print("🔄 [Recipe $i/${recipes.length}] Starting image generation for: $recipeName");
      
      // Create image generation task
      final task = recipeService.generateDishImage(recipeName).then((imageResult) {
        print("📸 [Recipe $i] Image generation completed for: $recipeName");
        print("📸 [Recipe $i] Image result type: ${imageResult.runtimeType}");
        print("📸 [Recipe $i] Image result: $imageResult");
        
        if (imageResult != null) {
          String imageUrl = '';
          
          if (imageResult is String) {
            imageUrl = imageResult;
            print("📸 [Recipe $i] Got string URL: $imageUrl");
          } else if (imageResult is Map && imageResult['image_url'] != null) {
            imageUrl = imageResult['image_url'].toString();
            print("📸 [Recipe $i] Got map URL: $imageUrl");
          } else if (imageResult is Uint8List) {
            print("📸 [Recipe $i] Got Uint8List image data");
            // For now, skip Uint8List as we need URLs
            imageUrl = '';
          }
          
          if (imageUrl.isNotEmpty) {
            recipe['recipe_image_url'] = imageUrl;
            print("✅ [Recipe $i] Successfully set image for $recipeName: $imageUrl");
          } else {
            print("⚠️ [Recipe $i] No valid image URL generated for $recipeName");
            // Set a fallback placeholder image
            recipe['recipe_image_url'] = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg';
            print("📸 [Recipe $i] Set fallback image for $recipeName");
          }
        } else {
          print("❌ [Recipe $i] Failed to generate image for $recipeName");
          // Set a fallback placeholder image
          recipe['recipe_image_url'] = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg';
          print("📸 [Recipe $i] Set fallback image for $recipeName due to null result");
        }
      }).catchError((error, stackTrace) {
        print("❌ [Recipe $i] Error generating image for $recipeName: $error");
        print("📋 [Recipe $i] Stack trace: $stackTrace");
        // Set a fallback placeholder image on error
        recipe['recipe_image_url'] = 'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg';
        print("📸 [Recipe $i] Set fallback image for $recipeName due to error");
      });
      
      imageGenerationTasks.add(task);
      
      // Add small delay between API calls to avoid overwhelming the server
      if (i < recipes.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    print("⏳ Waiting for ${imageGenerationTasks.length} image generation tasks to complete...");
    
    // Wait for all image generation tasks to complete
    await Future.wait(imageGenerationTasks);
    print("✅ Completed image generation for all recipes");
    
    // Final verification
    int successCount = 0;
    int fallbackCount = 0;
    for (final recipe in recipes) {
      if (recipe['recipe_image_url'] != null && recipe['recipe_image_url'].toString().isNotEmpty) {
        if (recipe['recipe_image_url'].toString().contains('pexels.com')) {
          fallbackCount++;
        } else {
          successCount++;
        }
      }
    }
    print("📊 Image Generation Summary: $successCount successful, $fallbackCount fallback images");
    
    return recipes;
  }

  Future<List<dynamic>> generateHomeRecipes() async {
    try {
      // Step 1: Generate dynamic preferences
      final preferences = await _generateDynamicPreferences();
      
      print("🎲 Generated Preferences: $preferences");
      
      // Step 2: Fetch fresh recipes directly from backend (no cache)
      print("📡 Sending request to: " + _dio.options.baseUrl + "/generate-recipes-ingredient");
      print("📦 Request data: $preferences");
      
      // Add retry logic for connection issues
      List<dynamic> recipes = [];
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          final response = await _dio.post(
            "/generate-recipes-ingredient",
            data: {
              'Meal_Type': [preferences['Meal_Type']?.toString() ?? 'lunch'],
              'Dietary_Restrictions': preferences['Dietary_Restrictions']?.toString() ?? 'None',
              'Cookware_Available': preferences['Cookware_Available'] ?? ['Gas Stove', 'Pan'],
              'Cooking_Time': preferences['Cooking_Time']?.toString() ?? '30 minutes',
              'Cuisine_Preference': preferences['Cuisine_Preference']?.toString() ?? 'Any',
              'Serving': int.tryParse(preferences['Serving']?.toString() ?? '1') ?? 1,
              'Ingredients_Available': preferences['Ingredients_Available'] ?? [],
            },
          );
          
          print("🔥 RAW HOME API RESPONSE: ${response.data}");
          print("📊 Response status: ${response.statusCode}");
          print("📋 Response headers: ${response.headers}");

          // Step 3: Process response
          List<dynamic> backendRecipes = [];
          
          if (response.data is Map) {
            if (response.data['Recipes'] != null) {
              backendRecipes = response.data['Recipes'] as List;
            } else if (response.data['recipes'] != null) {
              backendRecipes = response.data['recipes'] as List;
            } else if (response.data['data'] != null) {
              backendRecipes = response.data['data'] as List;
            }
          } else if (response.data is List) {
            backendRecipes = response.data as List;
          }
          
          if (backendRecipes.isEmpty) {
            throw Exception('No recipes found in API response');
          }
          
          recipes = backendRecipes;
          break; // Success, exit retry loop
          
        } catch (e) {
          retryCount++;
          print('❌ Attempt $retryCount failed: $e');
          
          if (retryCount >= maxRetries) {
            // If all retries fail, try to load cached recipes
            print('⚠️ All retries failed, attempting to load cached recipes...');
            recipes = await _loadCachedRecipesAsFallback();
            if (recipes.isNotEmpty) {
              print('✅ Using cached recipes as fallback (${recipes.length} recipes)');
            }
          } else {
            print('🔄 Retrying... (${retryCount}/$maxRetries)');
            await Future.delayed(Duration(seconds: 2 * retryCount)); // Exponential backoff
          }
        }
      }
      
      print("✅ Successfully fetched ${recipes.length} recipes from backend");
      
      // Generate images for recipes that don't have them
      recipes = await _generateRecipeImages(recipes);
      
      return recipes;
      
    } catch (e) {
      print('❌ Error fetching recipes: $e');
      
      // Try to get more details from DioException
      if (e is DioException) {
        print('🚨 DioException details:');
        print('   - Type: ${e.type}');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Status Message: ${e.response?.statusMessage}');
        print('   - Response Data: ${e.response?.data}');
        print('   - Headers: ${e.response?.headers}');
        
        // If it's a connection error, try cached recipes
        if (e.type == DioExceptionType.connectionError || 
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.error?.toString().contains('Connection closed') == true) {
          print('🔄 Connection error detected, loading cached recipes...');
          final cachedRecipes = await _loadCachedRecipesAsFallback();
          if (cachedRecipes.isNotEmpty) {
            return cachedRecipes;
          }
        }
      }
      
      rethrow;
    }
  }
      
  Future<List<dynamic>> generateWeeklyRecipes(Map<String, dynamic> preferences) async {
    try {
      // Use the new weekly recipes API endpoint
      print("📡 Sending request to: ${_dio.options.baseUrl}/recipes-weekly");
      print("📦 Request data: $preferences");
      
      final response = await _dio.post(
        "/recipes-weekly",
        data: preferences,
      );

      print("🔥 Weekly Recipes API Response: ${response.data}");

      // Process response
      List<dynamic> weeklyRecipes = [];
      
      if (response.data is Map && response.data['Recipes'] != null) {
        weeklyRecipes = response.data['Recipes'] as List;
      } else if (response.data is List) {
        weeklyRecipes = response.data as List;
      }
      
      print("✅ Successfully generated ${weeklyRecipes.length} weekly recipes");
      
      return weeklyRecipes;
      
    } catch (e) {
      print('❌ Error generating weekly recipes: $e');
      
      // Try to get more details from DioException
      if (e is DioException) {
        print('🚨 DioException details:');
        print('   - Type: ${e.type}');
        print('   - Status Code: ${e.response?.statusCode}');
        print('   - Status Message: ${e.response?.statusMessage}');
        print('   - Response Data: ${e.response?.data}');
        print('   - Headers: ${e.response?.headers}');
      }
      
      rethrow;
    }
  }
}