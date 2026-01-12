// lib/data/services/recipe_cache_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class RecipeCacheService {
  static const String _boxName = 'recipeCache';
  static const int _cacheDurationDays = 30; // Cache duration in days

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static String _generateCacheKey(List<Map<String, dynamic>> ingredients, Map<String, dynamic> preferences) {
    // Create a unique key based on ingredients and preferences
    final keyData = {
      'ingredients': ingredients,
      'preferences': preferences,
    };
    return jsonEncode(keyData);
  }

  static Future<List<Map<String, dynamic>>?> getCachedRecipes(
    List<Map<String, dynamic>> ingredients,
    Map<String, dynamic> preferences,
  ) async {
    try {
      final box = Hive.box(_boxName);
      final cacheKey = _generateCacheKey(ingredients, preferences);
      final cachedData = box.get(cacheKey);

      if (cachedData != null) {
        final data = Map<String, dynamic>.from(cachedData as Map);
        final timestamp = DateTime.parse(data['timestamp']);
        final now = DateTime.now();
        
        // Check if cache is still valid (30 days)
        if (now.difference(timestamp).inDays <= _cacheDurationDays) {
          final recipes = data['recipes'] as List?;
          if (recipes != null) {
            return recipes.cast<Map<String, dynamic>>();
          }
        } else {
          // Remove expired cache
          await box.delete(cacheKey);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached recipes: $e');
      return null;
    }
  }

  static Future<void> saveRecipes(
    List<Map<String, dynamic>> ingredients,
    Map<String, dynamic> preferences,
    List<Map<String, dynamic>> recipes,
  ) async {
    try {
      final box = Hive.box(_boxName);
      final cacheKey = _generateCacheKey(ingredients, preferences);
      
      await box.put(cacheKey, {
        'timestamp': DateTime.now().toIso8601String(),
        'recipes': recipes,
      });
    } catch (e) {
      debugPrint('Error saving recipes to cache: $e');
    }
  }
}