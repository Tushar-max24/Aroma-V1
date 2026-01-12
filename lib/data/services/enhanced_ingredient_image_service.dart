import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EnhancedIngredientImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';
  static String get _baseUrl => dotenv.env['MONGO_EXTERNAL_API_URL'] ?? "http://3.108.110.151:5001";

  /// Initialize the service (INSTANT mode - no MongoDB)
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Enhanced Ingredient Image Service initialized in INSTANT mode (no MongoDB/cache)');
      }
    }
  }

  /// Normalize ingredient name for consistent handling
  static String _normalizeIngredientName(String ingredientName) {
    return ingredientName.toLowerCase().trim();
  }

  /// Get ingredient image - HYBRID MODE (API + Instant)
  /// Returns provided imageUrl directly, otherwise generates using API
  static Future<String?> getIngredientImage(String ingredientName, {String? imageUrl}) async {
    final normalizedName = _normalizeIngredientName(ingredientName);
    
    if (kDebugMode) {
      print('🔍 [Enhanced Ingredient] Getting ingredient image for: "$ingredientName" -> normalized: "$normalizedName"');
      if (imageUrl != null) {
        print('🔍 [Enhanced Ingredient] Provided imageUrl: $imageUrl');
      }
    }
    
    // If imageUrl is provided and not empty, use it directly
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (kDebugMode) {
        print('🏷️ [Enhanced Ingredient] Cache Source: PROVIDED URL (INSTANT)');
        print('🔄 [Enhanced Ingredient] Using provided imageUrl: $imageUrl');
      }
      return imageUrl;
    }
    
    // No imageUrl provided - generate using API
    if (kDebugMode) {
      print('⚡ [Enhanced Ingredient] No imageUrl provided - GENERATING using API');
    }
    
    try {
      // Generate image using API
      final response = await http.post(
        Uri.parse('http://3.108.110.151:5001/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dish_name': normalizedName}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (kDebugMode) {
          print('📦 [Enhanced Ingredient] API response: ${data.keys.toList()}');
        }
        
        String? generatedImageUrl;
        
        // Handle different response formats
        if (data.containsKey('image_url')) {
          generatedImageUrl = data['image_url'].toString();
        } else if (data.containsKey('results') && data['results'] is Map) {
          final results = data['results'] as Map<String, dynamic>;
          
          // Try multiple possible keys for ingredient name
          final possibleKeys = [
            normalizedName,
            normalizedName.toLowerCase(),
            normalizedName.split(' ').map((w) => _capitalizeFirst(w)).join(' '),
            normalizedName.split(' ').map((w) => w.toLowerCase()).join(' ')
          ];
          
          for (final key in possibleKeys) {
            if (results.containsKey(key)) {
              final ingredientData = results[key] as Map<String, dynamic>;
              generatedImageUrl = ingredientData['image_url']?.toString() ?? '';
              if (kDebugMode) {
                print('🔑 [Enhanced Ingredient] Found image for "$normalizedName" using key "$key": $generatedImageUrl');
              }
              break;
            }
          }
        }
        
        if (generatedImageUrl != null && generatedImageUrl.isNotEmpty) {
          // Convert HTTP to HTTPS for S3 URLs
          if (generatedImageUrl.startsWith('http://') && generatedImageUrl.contains('s3')) {
            generatedImageUrl = generatedImageUrl.replaceFirst('http://', 'https://');
          }
          
          if (kDebugMode) {
            print('✅ [Enhanced Ingredient] API generated image: $generatedImageUrl');
          }
          return generatedImageUrl;
        } else {
          if (kDebugMode) {
            print('❌ [Enhanced Ingredient] No image URL found in API response for: $normalizedName');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('❌ [Enhanced Ingredient] API request failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Enhanced Ingredient] API exception for $normalizedName: $e');
      }
      return null;
    }
  }

  /// Cache ingredient image - DISABLED in INSTANT mode
  static Future<void> cacheIngredientImage(String ingredientName, String imageUrl) async {
    if (kDebugMode) {
      print('⚡ [Enhanced Ingredient] Cache DISABLED in INSTANT mode for: $ingredientName');
    }
    // No caching - instant display only
  }

  /// Verify image URL - DISABLED in INSTANT mode (returns true immediately)
  static Future<bool> verifyImageUrl(String imageUrl) async {
    if (kDebugMode) {
      print('⚡ [Enhanced Ingredient] URL verification DISABLED in INSTANT mode: $imageUrl');
    }
    return true; // Assume valid for instant display
  }

  /// Clear all caches - DISABLED in INSTANT mode
  static Future<void> clearAllCaches() async {
    if (kDebugMode) {
      print('⚡ [Enhanced Ingredient] Cache clearing DISABLED in INSTANT mode');
    }
    // No caches to clear
  }

  /// Get service status
  static String getServiceMode() {
    return 'HYBRID MODE (API + Instant)';
  }
  
  /// Helper method to capitalize first letter of a word
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
