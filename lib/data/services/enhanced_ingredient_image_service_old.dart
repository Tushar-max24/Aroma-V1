import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'mongo_ingredient_service.dart';
import 'session_cache_service.dart';

class EnhancedIngredientImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Enhanced Ingredient Image Service initialized with MongoDB-first workflow');
      }
    }
  }

  /// Normalize ingredient name for consistent database storage and lookup
  static String _normalizeIngredientName(String ingredientName) {
    return ingredientName.toLowerCase().trim();
  }

  /// Get ingredient image with multi-layer caching workflow
  /// 1. First check session cache (fastest)
  /// 2. Then check MongoDB ingredients collection
  /// 3. If not found, fetch from backend API and store in both caches
  /// 4. Return the image URL
  static Future<String?> getIngredientImage(String ingredientName, {String? imageUrl}) async {
    await initialize();
    
    final normalizedName = _normalizeIngredientName(ingredientName);
    
    if (kDebugMode) {
      print('🔍 [Enhanced Ingredient] Getting ingredient image for: "$ingredientName" -> normalized: "$normalizedName"');
      if (imageUrl != null) {
        print('🔍 [Enhanced Ingredient] Provided imageUrl: $imageUrl');
      }
    }
    
    try {
      // Step 1: Check session cache first (fastest)
      final sessionImageUrl = SessionCacheService.getIngredientImage(normalizedName);
      if (sessionImageUrl != null) {
        if (kDebugMode) {
          print('✅ [Enhanced Ingredient] FOUND IN SESSION CACHE: $normalizedName');
          print('🖼️ [Enhanced Ingredient] Session Image URL: $sessionImageUrl');
          print('🏷️ [Enhanced Ingredient] Cache Source: SESSION CACHE');
        }
        return sessionImageUrl;
      }

      if (kDebugMode) {
        print('❌ [Enhanced Ingredient] NOT FOUND IN SESSION CACHE: $normalizedName');
      }

      // Step 2: Check MongoDB ingredients collection
      final mongoIngredient = await MongoIngredientService.getIngredientByName(normalizedName);
      if (mongoIngredient != null && mongoIngredient['image_url'] != null) {
        final mongoImageUrl = mongoIngredient['image_url'].toString();
        if (mongoImageUrl.isNotEmpty) {
          if (kDebugMode) {
            print('✅ [Enhanced Ingredient] FOUND IN MONGODB: $normalizedName');
            print('📦 [Enhanced Ingredient] MongoDB Image URL: $mongoImageUrl');
            print('🏷️ [Enhanced Ingredient] Cache Source: MONGODB');
          }
          
          // Store in session cache for future fast access
          await SessionCacheService.storeIngredientImage(normalizedName, mongoImageUrl);
          
          return mongoImageUrl;
        }
      }

      if (kDebugMode) {
        print('❌ [Enhanced Ingredient] NOT FOUND IN MONGODB: $normalizedName');
        print('🏷️ [Enhanced Ingredient] Cache Source: BACKEND FALLBACK');
      }

      // Step 2: If not found in MongoDB, try backend API
      String? backendImageUrl;
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Use provided imageUrl if available
        backendImageUrl = imageUrl;
        if (kDebugMode) {
          print('🔄 [Enhanced Ingredient] Using provided imageUrl: $backendImageUrl');
          print('🏷️ [Enhanced Ingredient] Cache Source: PROVIDED URL');
        }
      } else {
        // Generate backend URL
        backendImageUrl = _generateBackendImageUrl(normalizedName);
        if (kDebugMode) {
          print('🔄 [Enhanced Ingredient] Generated backend URL: $backendImageUrl');
          print('🏷️ [Enhanced Ingredient] Cache Source: GENERATED URL');
        }
      }

      // Step 3: Verify backend URL works by making a lightweight request
      if (backendImageUrl != null) {
        final isValidUrl = await _verifyImageUrl(backendImageUrl);
        if (isValidUrl) {
          // Step 4: Store in MongoDB for future caching
          final success = await _storeIngredientInMongoDB(normalizedName, backendImageUrl);
          
          // Store in session cache for instant access during current session
          await SessionCacheService.storeIngredientImage(normalizedName, backendImageUrl);
          
          if (kDebugMode) {
            if (success) {
              print('✅ [Enhanced Ingredient] Stored ingredient in MongoDB: $normalizedName');
              print('💾 [Enhanced Ingredient] Stored ingredient in session cache: $normalizedName');
              print('🏷️ [Enhanced Ingredient] Cache Source: MONGODB (NEWLY STORED) + SESSION CACHE');
            } else {
              print('⚠️ [Enhanced Ingredient] Failed to store ingredient in MongoDB: $normalizedName');
              print('💾 [Enhanced Ingredient] Stored ingredient in session cache only: $normalizedName');
              print('🏷️ [Enhanced Ingredient] Cache Source: BACKEND (DIRECT) + SESSION CACHE');
            }
          }
          return backendImageUrl;
        } else {
          if (kDebugMode) {
            print('❌ [Enhanced Ingredient] Backend URL validation failed: $backendImageUrl');
            print('🏷️ [Enhanced Ingredient] Cache Source: FALLBACK');
          }
        }
      }

      // Step 5: If all else fails, return fallback
      if (kDebugMode) {
        print('❌ [Enhanced Ingredient] All attempts failed for: $normalizedName, using fallback');
        print('🏷️ [Enhanced Ingredient] Cache Source: FALLBACK ASSET');
      }
      return _fallbackImagePath;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced] Error getting ingredient image: $e, using fallback');
      }
      return _fallbackImagePath;
    }
  }

  /// Generate backend image URL for ingredient
  static String? _generateBackendImageUrl(String normalizedName) {
    final possibleUrls = [
      '$_baseUrl/v2/images/${normalizedName.replaceAll(' ', '_')}.png',
      '$_baseUrl/v2/images/${normalizedName.replaceAll(' ', '')}.png',
      '$_baseUrl/v2/images/$normalizedName.png',
      '$_baseUrl/ingredient_images/${normalizedName.replaceAll(' ', '_')}.png',
      '$_baseUrl/ingredient_images/$normalizedName.png',
    ];
    
    // Return the first URL (let the image widget handle 404s)
    return possibleUrls.isNotEmpty ? possibleUrls.first : null;
  }

  /// Verify if image URL is valid by making a HEAD request
  static Future<bool> _verifyImageUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final request = http.Request('HEAD', uri);
      final response = await request.send().timeout(Duration(seconds: 5));
      
      if (kDebugMode) {
        print('🔍 [Enhanced] Image URL verification: $imageUrl -> ${response.statusCode}');
      }
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced] Image URL verification error: $e');
      }
      return false;
    }
  }

  /// Store ingredient in MongoDB for future caching
  static Future<bool> _storeIngredientInMongoDB(String ingredientName, String imageUrl) async {
    try {
      final ingredientData = {
        'name': ingredientName,
        'image_url': imageUrl,
        'common_units': ['g', 'pcs'], // Default units
        'nutrition_per_100g': {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fats': 0,
          'fiber': 0,
          'sugar': 0
        }
      };
      
      return await MongoIngredientService.storeSingleIngredient(ingredientData);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced] Error storing ingredient in MongoDB: $e');
      }
      return false;
    }
  }

  /// Preload images for a list of ingredients
  static Future<void> preloadImages(List<String> ingredientNames) async {
    await initialize();
    
    if (kDebugMode) {
      print('🔄 [Enhanced] Preloading ${ingredientNames.length} ingredient images...');
    }
    
    for (final ingredientName in ingredientNames) {
      try {
        await getIngredientImage(ingredientName);
      } catch (e) {
        if (kDebugMode) {
          print('❌ [Enhanced] Error preloading image for $ingredientName: $e');
        }
      }
    }
    
    if (kDebugMode) {
      print('✅ [Enhanced] Preloading completed');
    }
  }

  /// Clear all cached images from MongoDB (optional maintenance)
  static Future<void> clearMongoDBCache() async {
    if (kDebugMode) {
      print('⚠️ [Enhanced] MongoDB cache clearing not implemented - ingredients are stored permanently');
    }
  }

  /// Get statistics about cached ingredients
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      // This would require an additional endpoint in the MongoDB server
      // For now, return basic info
      return {
        'service': 'Enhanced Ingredient Image Service',
        'workflow': 'MongoDB-first',
        'fallback_image': _fallbackImagePath,
        'base_url': _baseUrl,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced] Error getting cache stats: $e');
      }
      return {};
    }
  }
}
