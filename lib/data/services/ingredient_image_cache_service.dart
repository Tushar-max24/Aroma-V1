import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient_image_model.dart';

class IngredientImageCacheService {
  static const String _cacheKey = 'ingredient_images_cache';
  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<IngredientImageModel?> getCachedImage(String ingredientName) async {
    await initialize();
    
    try {
      final cacheData = _prefs!.getString(_cacheKey);
      if (cacheData == null) return null;

      final Map<String, dynamic> cache = jsonDecode(cacheData);
      final ingredientKey = ingredientName.toLowerCase().trim();
      
      if (cache.containsKey(ingredientKey)) {
        final imageData = cache[ingredientKey];
        final model = IngredientImageModel.fromJson(imageData);
        
        // Update last accessed time
        final updatedModel = model.copyWith(
          lastAccessed: DateTime.now(),
        );
        
        // Save the updated access time
        cache[ingredientKey] = updatedModel.toJson();
        await _prefs!.setString(_cacheKey, jsonEncode(cache));
        
        return updatedModel;
      }
      
      return null;
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error getting cached image: $e');
      }
      return null;
    }
  }

  static Future<void> cacheImage(
    String ingredientName,
    String imageUrl,
    String localPath,
  ) async {
    await initialize();
    
    try {
      final cacheData = _prefs!.getString(_cacheKey);
      final Map<String, dynamic> cache = cacheData != null 
          ? jsonDecode(cacheData) 
          : <String, dynamic>{};

      final ingredientKey = ingredientName.toLowerCase().trim();
      final now = DateTime.now();
      
      final imageModel = IngredientImageModel(
        id: '${ingredientKey}_${now.millisecondsSinceEpoch}',
        ingredientName: ingredientName,
        imageUrl: imageUrl,
        localPath: localPath,
        createdAt: now,
        lastAccessed: now,
      );

      cache[ingredientKey] = imageModel.toJson();
      await _prefs!.setString(_cacheKey, jsonEncode(cache));
      
      if (true) { // kDebugMode equivalent
        print('Cached image for ingredient: $ingredientName');
      }
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error caching image: $e');
      }
    }
  }

  static Future<List<IngredientImageModel>> getAllCachedImages() async {
    await initialize();
    
    try {
      final cacheData = _prefs!.getString(_cacheKey);
      if (cacheData == null) return [];

      final Map<String, dynamic> cache = jsonDecode(cacheData);
      final List<IngredientImageModel> images = [];
      
      for (final entry in cache.entries) {
        images.add(IngredientImageModel.fromJson(entry.value));
      }
      
      // Sort by last accessed time (most recent first)
      images.sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
      
      return images;
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error getting all cached images: $e');
      }
      return [];
    }
  }

  static Future<void> clearCache() async {
    await initialize();
    
    try {
      await _prefs!.remove(_cacheKey);
      if (true) { // kDebugMode equivalent
        print('Ingredient image cache cleared');
      }
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error clearing cache: $e');
      }
    }
  }

  static Future<void> removeCachedImage(String ingredientName) async {
    await initialize();
    
    try {
      final cacheData = _prefs!.getString(_cacheKey);
      if (cacheData == null) return;

      final Map<String, dynamic> cache = jsonDecode(cacheData);
      final ingredientKey = ingredientName.toLowerCase().trim();
      
      if (cache.containsKey(ingredientKey)) {
        cache.remove(ingredientKey);
        await _prefs!.setString(_cacheKey, jsonEncode(cache));
        
        if (true) { // kDebugMode equivalent
          print('Removed cached image for: $ingredientName');
        }
      }
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error removing cached image: $e');
      }
    }
  }

  static Future<int> getCacheSize() async {
    await initialize();
    
    try {
      final cacheData = _prefs!.getString(_cacheKey);
      if (cacheData == null) return 0;

      final Map<String, dynamic> cache = jsonDecode(cacheData);
      return cache.length;
    } catch (e) {
      if (true) { // kDebugMode equivalent
        print('Error getting cache size: $e');
      }
      return 0;
    }
  }
}
