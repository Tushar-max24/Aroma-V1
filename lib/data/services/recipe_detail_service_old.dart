import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RecipeDetailService {
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  
  // Cache to store recipe details to avoid repeated API calls
  static final Map<String, Map<String, dynamic>> _recipeDetailCache = {};

  // Fetch recipe details from the backend
  static Future<Map<String, dynamic>> fetchRecipeDetails(String recipeName) async {
    // Return cached data if available
    if (_recipeDetailCache.containsKey(recipeName)) {
      final cachedData = _recipeDetailCache[recipeName]!;
      // Track view even for cached data
      await trackRecipeView(recipeName, cachedData);
      return cachedData;
    }

    try {
      // Try to fetch recipe details from main endpoint
      final response = await _dio.post(
        "/generate-recipe-details",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _recipeDetailCache[recipeName] = data;
          // Track recipe view and store details
          await trackRecipeView(recipeName, data);
          await storeRecipeDetails(recipeName, data);
          return data;
        }
      }
      
      // If specific endpoint fails, try to fallback endpoints
      final fallbackData = await _fetchFallbackDetails(recipeName);
      _recipeDetailCache[recipeName] = fallbackData;
      // Track view and store fallback data as well
      await trackRecipeView(recipeName, fallbackData);
      await storeRecipeDetails(recipeName, fallbackData);
      return fallbackData;
    } catch (e) {
      debugPrint('Error fetching recipe details: $e');
      final fallbackData = await _fetchFallbackDetails(recipeName);
      _recipeDetailCache[recipeName] = fallbackData;
      // Track view and store fallback data
      await trackRecipeView(recipeName, fallbackData);
      await storeRecipeDetails(recipeName, fallbackData);
      return fallbackData;
    }
  }

  // Fallback to individual endpoints if the combined endpoint fails
  static Future<Map<String, dynamic>> _fetchFallbackDetails(String recipeName) async {
    try {
      // Try to get all data in parallel
      final results = await Future.wait([
        _fetchCookware(recipeName),
        _fetchCookingSteps(recipeName),
        _fetchReviews(recipeName),
        _fetchSimilarRecipes(recipeName),
      ], eagerError: true);

      final result = {
        'cookware': results[0],
        'steps': results[1],
        'reviews': results[2],
        'similar_recipes': results[3],
      };
      
      _recipeDetailCache[recipeName] = result;
      return result;
    } catch (e) {
      debugPrint('Error in fallback details: $e');
      // Return empty data structure if all fails
      return {
        'cookware': [],
        'steps': [],
        'reviews': [],
        'similar_recipes': [],
      };
    }
  }

  static Future<List<String>> _fetchCookware(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-cookware",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['cookware'] is List) {
          return List<String>.from(data['cookware']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cookware: $e');
      return [];
    }
  }

  static Future<List<String>> _fetchCookingSteps(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-steps",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['steps'] is List) {
          return List<String>.from(data['steps']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching cooking steps: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchReviews(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-recipe-reviews",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['reviews'] is List) {
          return List<Map<String, dynamic>>.from(data['reviews']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _fetchSimilarRecipes(String recipeName) async {
    try {
      final response = await _dio.post(
        "/generate-similar-recipes",
        data: {"dish_name": recipeName},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['similar'] is List) {
          return List<Map<String, dynamic>>.from(data['similar']);
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching similar recipes: $e');
      return [];
    }
  }

  /// Track recipe view and store in MongoDB recipes collection
  static Future<void> trackRecipeView(String recipeName, Map<String, dynamic> recipeDetails) async {
    try {
      debugPrint("📊 Tracking recipe view for: $recipeName");
      
      final response = await http.post(
        Uri.parse("$_baseUrl/track-recipe-view"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "recipe_name": recipeName,
          "viewed_at": DateTime.now().toIso8601String(),
          "recipe_details": recipeDetails,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint("✅ Recipe view tracked successfully");
      } else {
        debugPrint("⚠️ Failed to track recipe view: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error tracking recipe view: $e");
    }
  }

  /// Store recipe details - DISABLED in INSTANT mode
  static Future<void> storeRecipeDetails(String recipeName, Map<String, dynamic> recipeData) async {
    if (kDebugMode) {
      print('⚡ [RecipeDetailService] Storage DISABLED in INSTANT mode for: $recipeName');
  static Future<void> storeRecipeDetails(String recipeName, Map<String, dynamic> recipeDetails) async {
    print("🔥🔥🔥 DEBUG: storeRecipeDetails CALLED with recipe: $recipeName");
    print("🔥🔥🔥 DEBUG: recipeDetails keys: ${recipeDetails.keys}");
    
    try {
      debugPrint("📊 Storing recipe details for: $recipeName");
      
      // Use the same MongoDB URL as other services - try external first, then local
      final externalMongoUrl = dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";
      final localMongoUrl = dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";
      
      // Try external MongoDB API first (same pattern as other services)
      final mongoApiUrls = [
        externalMongoUrl,
        localMongoUrl,
        "http://127.0.0.1:3000",
        "http://10.231.82.169:3000",
      ];
      
      // Format recipe data to match MongoDB schema
      final formattedRecipeData = _formatRecipeForMongoDB(recipeName, recipeDetails);
      debugPrint("📝 Formatted recipe data: ${formattedRecipeData.keys}");
      
      bool storedSuccessfully = false;
      
      for (int i = 0; i < mongoApiUrls.length; i++) {
        final mongoApiUrl = mongoApiUrls[i];
        debugPrint("🔍 Trying MongoDB storage ${i + 1}/${mongoApiUrls.length}: $mongoApiUrl");
        
        try {
          final response = await http.post(
            Uri.parse("$mongoApiUrl/api/recipes"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(formattedRecipeData),
          ).timeout(const Duration(seconds: 10));

          debugPrint("📌 MongoDB Storage Response: ${response.statusCode}");
          debugPrint("📌 Response body: ${response.body}");

          if (response.statusCode == 201 || response.statusCode == 200) {
            debugPrint("✅ Recipe details stored successfully in MongoDB");
            final responseData = jsonDecode(response.body);
            debugPrint("📝 Recipe ID: ${responseData['recipeId'] ?? responseData['_id']}");
            storedSuccessfully = true;
            break;
          } else {
            debugPrint("⚠️ Failed to store recipe details to $mongoApiUrl: ${response.statusCode}");
            continue;
          }
        } catch (e) {
          debugPrint("❌ Error storing to $mongoApiUrl: $e");
          continue;
        }
      }
      
      if (!storedSuccessfully) {
        debugPrint("❌ All MongoDB storage attempts failed for recipe: $recipeName");
      }
      
    } catch (e) {
      debugPrint("❌ Critical error in storeRecipeDetails: $e");
    }
  }

  /// Format recipe data to match MongoDB schema structure
  static Map<String, dynamic> _formatRecipeForMongoDB(String recipeName, Map<String, dynamic> recipeDetails) {
    // Extract basic recipe information
    final recipeData = recipeDetails['recipe'] ?? {};
    final ingredients = recipeDetails['ingredients'] ?? [];
    final cookingSteps = recipeDetails['cooking_steps'] ?? recipeDetails['steps'] ?? [];
    final cookware = recipeDetails['cookware'] ?? [];
    final nutrition = recipeDetails['nutrition'] ?? {};
    
    // DEBUG: Print cookware data structure
    print("🔥 DEBUG: Cookware data from recipeDetails: $cookware");
    print("🔥 DEBUG: Cookware data type: ${cookware.runtimeType}");
    print("🔥 DEBUG: recipeDetails keys: ${recipeDetails.keys}");
    
    // Try alternative cookware field names and also check if cookware is in different locations
    final alternativeCookware = recipeDetails['cookware_items'] ?? 
                               recipeDetails['cookwareItems'] ?? 
                               recipeDetails['Cookware'] ?? 
                               recipeData['cookware'] ?? 
                               recipeData['Cookware'] ?? 
                               [];
    
    // Also check if cookware is in different data structures
    if (alternativeCookware.isEmpty) {
      // Check if cookware is in cooking steps or other nested structures
      final cookingSteps = recipeDetails['cooking_steps'] ?? recipeDetails['steps'] ?? [];
      for (final step in cookingSteps) {
        if (step is Map && step['cookware'] != null) {
          final stepCookware = step['cookware'];
          if (stepCookware is List) {
            alternativeCookware.addAll(List<String>.from(stepCookware));
          } else if (stepCookware is String) {
            alternativeCookware.add(stepCookware);
          }
        }
      }
      
      // Check if cookware is in ingredients or other fields
      final ingredients = recipeDetails['ingredients'] ?? [];
      for (final ingredient in ingredients) {
        if (ingredient is Map && ingredient['cookware'] != null) {
          final ingredientCookware = ingredient['cookware'];
          if (ingredientCookware is List) {
            alternativeCookware.addAll(List<String>.from(ingredientCookware));
          } else if (ingredientCookware is String) {
            alternativeCookware.add(ingredientCookware);
          }
        }
      }
    }
    
    print("🔥 DEBUG: Alternative cookware data: $alternativeCookware");
    
    // DEBUG: Print image data structure
    print("🔥 DEBUG: Image data from recipeDetails['image_url']: ${recipeDetails['image_url']}");
    print("🔥 DEBUG: Image data from recipeData['image_url']: ${recipeData['image_url']}");
    print("🔥 DEBUG: Image data from recipeDetails['Image']: ${recipeDetails['Image']}");
    print("🔥 DEBUG: Image data from recipeData['Image']: ${recipeData['Image']}");
    
    // Try multiple image field names
    String imageUrl = recipeData['image_url'] ?? 
                    recipeData['Image']?['image_url']?.toString() ??
                    recipeDetails['image_url'] ?? 
                    recipeDetails['Image']?['image_url']?.toString() ??
                    recipeDetails['recipe_image_url'] ?? 
                    '';
    print("🔥 DEBUG: Final extracted image URL: $imageUrl");
    
    // Format ingredients
    final formattedIngredients = (ingredients as List).map((ingredient) {
      if (ingredient is Map) {
        return {
          "item": ingredient['name'] ?? ingredient['item'] ?? 'Unknown',
          "quantity": ingredient['quantity'] ?? ingredient['amount'] ?? 'To taste',
          "image_url": ingredient['image_url'] ?? '',
        };
      } else {
        return {
          "item": ingredient.toString(),
          "quantity": 'To taste',
          "image_url": '',
        };
      }
    }).toList();

    // Format cooking steps
    final formattedCookingSteps = (cookingSteps as List).asMap().entries.map((entry) {
      final stepNumber = entry.key + 1;
      final step = entry.value;
      
      if (step is Map) {
        return {
          "step": stepNumber,
          "instruction": step['instruction'] ?? step['text'] ?? step.toString(),
          "time": step['time'] ?? '5 minutes',
          "ingredients_used": step['ingredients_used'] ?? [],
          "tips": step['tips'] ?? [],
        };
      } else {
        return {
          "step": stepNumber,
          "instruction": step.toString(),
          "time": '5 minutes',
          "ingredients_used": [],
          "tips": [],
        };
      }
    }).toList();

    // Extract needed ingredients list
    final neededIngredients = formattedIngredients
        .map((ing) => ing['item'] as String)
        .where((item) => item.isNotEmpty && item != 'Unknown')
        .toList();

    // Generate tags from available data
    final tags = {
      "meal_type": recipeData['meal_type'] ?? recipeData['Meal_Type'] ?? 'Lunch',
      "dietary": recipeData['dietary'] ?? recipeData['Dietary_Restrictions'] ?? 'Vegetarian',
      "cuisine": recipeData['cuisine'] ?? recipeData['Cuisine_Preference'] ?? 'Indian',
      "cooking_time": recipeData['cooking_time'] ?? recipeData['Cooking_Time'] ?? '30 minutes',
      "cookware": (alternativeCookware.isNotEmpty ? alternativeCookware : ['Pan', 'Gas Stove', 'Mixing Bowl']), // Fallback if empty
    };

    return {
      "recipe_name": recipeName,
      "recipe_description": recipeData['description'] ?? recipeData['Description'] ?? 
                          'A delicious recipe prepared with fresh ingredients.',
      "difficulty": recipeData['difficulty'] ?? 'Easy',
      "serving": int.tryParse(recipeData['serving']?.toString() ?? '2') ?? 2,
      "total_time": recipeData['total_time'] ?? recipeData['Cooking_Time'] ?? '30 minutes',
      "recipe_image_url": imageUrl,
      "ingredients": formattedIngredients,
      "cooking_steps": formattedCookingSteps,
      "nutrition": {
        "calories": nutrition['calories'] ?? 0,
        "protein": nutrition['protein'] ?? 0,
        "carbs": nutrition['carbs'] ?? 0,
        "fats": nutrition['fats'] ?? 0,
        "fiber": nutrition['fiber'] ?? 0,
      },
      "tags": tags,
      "needed_ingredients": neededIngredients,
      "source": "generated",
      "status": true,
    };
  }
}
