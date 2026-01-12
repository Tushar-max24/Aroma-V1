import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EnhancedRecipeImageService {
  static bool _isInitialized = false;
  static const String _fallbackImagePath = 'assets/images/pantry/temp_pantry.png';

  /// Initialize the service (INSTANT mode - no MongoDB)
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = true;
      if (kDebugMode) {
        print('✅ Enhanced Recipe Image Service initialized in INSTANT mode (no MongoDB/cache)');
      }
    }
  }

  /// Normalize recipe name for consistent handling
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

  /// Cache recipe image - DISABLED in INSTANT mode
  static Future<void> cacheRecipeImage(String recipeName, String imageUrl) async {
    if (kDebugMode) {
      print('⚡ [Enhanced Recipe] Cache DISABLED in INSTANT mode for: $recipeName');
    }
    // No caching - instant display only
  }

  /// Verify image URL - DISABLED in INSTANT mode (returns true immediately)
  static Future<bool> verifyImageUrl(String imageUrl) async {
    if (kDebugMode) {
      print('⚡ [Enhanced Recipe] URL verification DISABLED in INSTANT mode: $imageUrl');
    }
    return true; // Assume valid for instant display
  }

  /// Clear all caches - DISABLED in INSTANT mode
  static Future<void> clearAllCaches() async {
    if (kDebugMode) {
      print('⚡ [Enhanced Recipe] Cache clearing DISABLED in INSTANT mode');
    }
    // No caches to clear
  }

  /// Get service status
  static String getServiceMode() {
    return 'INSTANT MODE (No MongoDB/Cache)';
  }
}
