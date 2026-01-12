import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'mongo_ingredient_service.dart';
import 'session_cache_service.dart';

class EnhancedRecipeImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';
  static String get _mongoApiBaseUrl => dotenv.env['MONGO_API_BASE_URL'] ?? "http://localhost:3000";

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Enhanced Recipe Image Service initialized with MongoDB-first workflow');
      }
    }
  }

  /// Normalize recipe name for consistent database storage and lookup
  static String _normalizeRecipeName(String recipeName) {
    return recipeName.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
  }

  /// Get recipe image - INSTANT mode (no MongoDB/cache)
  /// Returns the provided imageUrl directly for instant display
  static Future<String?> getRecipeImage(String recipeName, {String? imageUrl}) async {
    final normalizedName = _normalizeRecipeName(recipeName);
    
    if (kDebugMode) {
      print('🔍 [Enhanced Recipe] Getting recipe image for: "$recipeName" -> normalized: "$normalizedName"');
      if (imageUrl != null) {
        print('🔍 [Enhanced Recipe] Provided imageUrl: $imageUrl');
      }
      print('⚡ [Enhanced Recipe] INSTANT MODE - Skipping MongoDB/cache checks');
    }
    
    // INSTANT MODE: Return provided imageUrl directly without any cache/MongoDB operations
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (kDebugMode) {
        print('🏷️ [Enhanced Recipe] Cache Source: PROVIDED URL (INSTANT)');
        print('🔄 [Enhanced Recipe] Using provided imageUrl: $imageUrl');
      }
      return imageUrl;
    }
    
    // Fallback to null if no imageUrl provided
    if (kDebugMode) {
      print('❌ [Enhanced Recipe] No imageUrl provided for: $recipeName');
    }
    return null;
  }
          print('🖼️ [Enhanced Recipe] Session Image URL: $sessionImageUrl');
          print('🏷️ [Enhanced Recipe] Cache Source: SESSION CACHE');
        }
        return sessionImageUrl;
      }

      if (kDebugMode) {
        print('❌ [Enhanced Recipe] NOT FOUND IN SESSION CACHE: $normalizedName');
      }

      // Step 2: Check MongoDB recipes collection
      final mongoRecipe = await _getRecipeFromMongoDB(normalizedName);
      if (mongoRecipe != null && mongoRecipe['image_url'] != null) {
        final mongoImageUrl = mongoRecipe['image_url'].toString();
        if (mongoImageUrl.isNotEmpty) {
          if (kDebugMode) {
            print('✅ [Enhanced Recipe] FOUND IN MONGODB: $normalizedName');
            print('🖼️ [Enhanced Recipe] MongoDB Image URL: $mongoImageUrl');
            print('🏷️ [Enhanced Recipe] Cache Source: MONGODB');
          }
          
          // Store in session cache for future fast access
          await SessionCacheService.storeRecipeImage(normalizedName, mongoImageUrl);
          
          return mongoImageUrl;
        }
      }

      if (kDebugMode) {
        print('❌ [Enhanced Recipe] NOT FOUND IN MONGODB: $normalizedName');
        print('🏷️ [Enhanced Recipe] Cache Source: BACKEND FALLBACK');
      }

      // Step 2: If not found in MongoDB, use provided image URL or fallback
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Use provided imageUrl if available
        if (kDebugMode) {
          print('🔄 [Enhanced Recipe] Using provided imageUrl: $imageUrl');
          print('🏷️ [Enhanced Recipe] Cache Source: PROVIDED URL');
        }
        
        // Step 3: Verify URL and store in MongoDB for future caching
        final isValidUrl = await _verifyImageUrl(imageUrl);
        if (isValidUrl) {
          await _storeRecipeImageInMongoDB(normalizedName, imageUrl);
          
          // Store in session cache for instant access during current session
          await SessionCacheService.storeRecipeImage(normalizedName, imageUrl);
          
          if (kDebugMode) {
            print('✅ [Enhanced Recipe] Stored recipe image in MongoDB: $normalizedName');
            print('💾 [Enhanced Recipe] Stored recipe image in session cache: $normalizedName');
            print('🏷️ [Enhanced Recipe] Cache Source: MONGODB (NEWLY STORED) + SESSION CACHE');
          }
          return imageUrl;
        } else {
          if (kDebugMode) {
            print('❌ [Enhanced Recipe] Provided URL validation failed: $imageUrl');
            print('🏷️ [Enhanced Recipe] Cache Source: FALLBACK');
          }
        }
      }

      // Step 4: If all else fails, return fallback
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] All attempts failed for: $normalizedName, using fallback');
        print('🏷️ [Enhanced Recipe] Cache Source: FALLBACK ASSET');
      }
      return _fallbackImagePath;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error getting recipe image: $e, using fallback');
      }
      return _fallbackImagePath;
    }
  }

  /// Get recipe from MongoDB by name
  static Future<Map<String, dynamic>?> _getRecipeFromMongoDB(String normalizedName) async {
    try {
      final url = Uri.parse("$_mongoApiBaseUrl/api/recipes/name/$normalizedName");
      
      final response = await http.get(url);

      if (kDebugMode) {
        print('📌 MongoDB Recipe Get Response: ${response.statusCode}');
        print('📌 MongoDB Recipe Get Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else if (response.statusCode == 404) {
        if (kDebugMode) {
          print('ℹ️ Recipe not found: $normalizedName');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch recipe: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching recipe from MongoDB: $e');
      }
      return null;
    }
  }

  /// Verify if image URL is valid by making a HEAD request
  static Future<bool> _verifyImageUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final request = http.Request('HEAD', uri);
      final response = await request.send().timeout(Duration(seconds: 5));
      
      if (kDebugMode) {
        print('🔍 [Enhanced Recipe] Image URL verification: $imageUrl -> ${response.statusCode}');
      }
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Image URL verification error: $e');
      }
      return false;
    }
  }

  /// Store recipe image in MongoDB for future caching
  static Future<bool> _storeRecipeImageInMongoDB(String recipeName, String imageUrl) async {
    try {
      // First check if recipe already exists
      final existingRecipe = await _getRecipeFromMongoDB(recipeName);
      if (existingRecipe != null) {
        if (kDebugMode) {
          print('ℹ️ [Enhanced Recipe] Recipe already exists: $recipeName');
        }
        return true;
      }

      // Create minimal recipe data for image storage
      final recipeData = {
        'name': recipeName,
        'image_url': imageUrl,
        'cuisine': 'Unknown',
        'cook_time': 'Unknown',
        'servings': 1,
        'description': 'Recipe image cached for future use',
        'ingredients': [],
        'cooking_steps': [],
        'nutrition': {},
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final url = Uri.parse("$_mongoApiBaseUrl/api/recipes");
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(recipeData),
      ).timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print('📌 MongoDB Recipe Store Response: ${response.statusCode}');
        print('📌 MongoDB Recipe Store Body: ${response.body}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ [Enhanced Recipe] Stored recipe image in MongoDB: $recipeName');
        }
        return true;
      } else if (response.statusCode == 400) {
        if (kDebugMode) {
          print('⚠️ [Enhanced Recipe] Recipe already exists: $recipeName');
        }
        return true; // Treat as success since it already exists
      } else {
        if (kDebugMode) {
          print('❌ [Enhanced Recipe] Failed to store recipe image: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error storing recipe image in MongoDB: $e');
      }
      return false;
    }
  }

  /// Preload images for a list of recipes
  static Future<void> preloadImages(List<String> recipeNames) async {
    await initialize();
    
    if (kDebugMode) {
      print('🔄 [Enhanced Recipe] Preloading ${recipeNames.length} recipe images...');
    }
    
    for (final recipeName in recipeNames) {
      try {
        await getRecipeImage(recipeName);
      } catch (e) {
        if (kDebugMode) {
          print('❌ [Enhanced Recipe] Error preloading image for $recipeName: $e');
        }
      }
    }
    
    if (kDebugMode) {
      print('✅ [Enhanced Recipe] Preloading completed');
    }
  }

  /// Get statistics about cached recipes
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return {
        'service': 'Enhanced Recipe Image Service',
        'workflow': 'MongoDB-first',
        'fallback_image': _fallbackImagePath,
        'mongo_api_base_url': _mongoApiBaseUrl,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Recipe] Error getting cache stats: $e');
      }
      return {};
    }
  }
}
