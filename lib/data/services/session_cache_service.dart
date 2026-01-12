import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Session-based local cache service
/// Caches data during the current app session and clears on app close
class SessionCacheService {
  static bool _isInitialized = false;
  static DateTime? _sessionStartTime;
  
  // Session cache storage
  static final Map<String, dynamic> _sessionCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static final Map<String, int> _cacheAccessCounts = {};
  
  // Cache categories for better organization
  static const String _recipeImagesCategory = 'recipe_images';
  static const String _ingredientImagesCategory = 'ingredient_images';
  static const String _recipeDetailsCategory = 'recipe_details';
  static const String _cookingStepsCategory = 'cooking_steps';
  static const String _textDataCategory = 'text_data';
  
  // Cache limits to prevent memory issues
  static const int _maxCacheSize = 500; // Maximum number of items
  static const int _maxImageCacheSize = 200; // Maximum image items
  static const Duration _sessionTimeout = Duration(hours: 4); // Session timeout
  
  /// Initialize the session cache service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _sessionStartTime = DateTime.now();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Session Cache Service initialized');
        print('🕐 [Session Cache] Session started at: $_sessionStartTime');
      }
    }
  }

  /// Generate cache key with category
  static String _generateCacheKey(String category, String identifier) {
    return '${category}_${identifier.toLowerCase().trim()}';
  }

  /// Store data in session cache
  static Future<void> storeData<T>(
    String category, 
    String identifier, 
    T data, {
    Duration? ttl,
  }) async {
    await initialize();
    
    final key = _generateCacheKey(category, identifier);
    final now = DateTime.now();
    
    // Check cache size limits
    if (_sessionCache.length >= _maxCacheSize) {
      await _evictLeastUsedItems();
    }
    
    // Specific category limits
    if ((category == _recipeImagesCategory || category == _ingredientImagesCategory) &&
        _getImageCacheSize() >= _maxImageCacheSize) {
      await _evictOldestImages();
    }
    
    // Store data with metadata
    _sessionCache[key] = data;
    _cacheTimestamps[key] = now;
    _cacheAccessCounts[key] = (_cacheAccessCounts[key] ?? 0) + 1;
    
    if (kDebugMode) {
      print('💾 [Session Cache] Stored: $category/$identifier');
      print('📊 [Session Cache] Total items: ${_sessionCache.length}');
      print('🖼️ [Session Cache] Image items: ${_getImageCacheSize()}');
    }
  }

  /// Get data from session cache
  static T? getData<T>(String category, String identifier) {
    if (!_isInitialized) return null;
    
    final key = _generateCacheKey(category, identifier);
    
    if (_sessionCache.containsKey(key)) {
      // Check if cache item is still valid
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && !_isExpired(timestamp)) {
        // Update access count
        _cacheAccessCounts[key] = (_cacheAccessCounts[key] ?? 0) + 1;
        
        if (kDebugMode) {
          print('✅ [Session Cache] Hit: $category/$identifier');
          print('📈 [Session Cache] Access count: ${_cacheAccessCounts[key]}');
        }
        
        return _sessionCache[key] as T?;
      } else {
        // Remove expired item
        _removeCacheItem(key);
        if (kDebugMode) {
          print('⏰ [Session Cache] Expired: $category/$identifier');
        }
      }
    }
    
    if (kDebugMode) {
      print('❌ [Session Cache] Miss: $category/$identifier');
    }
    
    return null;
  }

  /// Check if data exists in session cache
  static bool hasData(String category, String identifier) {
    if (!_isInitialized) return false;
    
    final key = _generateCacheKey(category, identifier);
    
    if (_sessionCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      return timestamp != null && !_isExpired(timestamp);
    }
    
    return false;
  }

  /// Store recipe image in session cache
  static Future<void> storeRecipeImage(String recipeName, String imageUrl) async {
    await storeData(_recipeImagesCategory, recipeName, imageUrl);
  }

  /// Get recipe image from session cache
  static String? getRecipeImage(String recipeName) {
    return getData<String>(_recipeImagesCategory, recipeName);
  }

  /// Store ingredient image in session cache
  static Future<void> storeIngredientImage(String ingredientName, String imageUrl) async {
    await storeData(_ingredientImagesCategory, ingredientName, imageUrl);
  }

  /// Get ingredient image from session cache
  static String? getIngredientImage(String ingredientName) {
    return getData<String>(_ingredientImagesCategory, ingredientName);
  }

  /// Store recipe details in session cache
  static Future<void> storeRecipeDetails(String recipeName, Map<String, dynamic> recipeData) async {
    await storeData(_recipeDetailsCategory, recipeName, recipeData);
  }

  /// Get recipe details from session cache
  static Map<String, dynamic>? getRecipeDetails(String recipeName) {
    return getData<Map<String, dynamic>>(_recipeDetailsCategory, recipeName);
  }

  /// Store cooking steps in session cache
  static Future<void> storeCookingSteps(String recipeName, List<Map<String, dynamic>> steps) async {
    await storeData(_cookingStepsCategory, recipeName, steps);
  }

  /// Get cooking steps from session cache
  static List<Map<String, dynamic>>? getCookingSteps(String recipeName) {
    return getData<List<Map<String, dynamic>>>(_cookingStepsCategory, recipeName);
  }

  /// Store text data in session cache
  static Future<void> storeTextData(String key, String textData) async {
    await storeData(_textDataCategory, key, textData);
  }

  /// Get text data from session cache
  static String? getTextData(String key) {
    return getData<String>(_textDataCategory, key);
  }

  /// Check if cache timestamp is expired
  static bool _isExpired(DateTime timestamp) {
    final now = DateTime.now();
    final age = now.difference(timestamp);
    return age > _sessionTimeout;
  }

  /// Get current image cache size
  static int _getImageCacheSize() {
    int count = 0;
    for (final key in _sessionCache.keys) {
      if (key.startsWith(_recipeImagesCategory) || key.startsWith(_ingredientImagesCategory)) {
        count++;
      }
    }
    return count;
  }

  /// Evict least used items when cache is full
  static Future<void> _evictLeastUsedItems() async {
    if (_sessionCache.isEmpty) return;
    
    // Sort items by access count (least used first)
    final sortedItems = _cacheAccessCounts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove bottom 20% of items
    final itemsToRemove = (sortedItems.length * 0.2).ceil();
    for (int i = 0; i < itemsToRemove && i < sortedItems.length; i++) {
      _removeCacheItem(sortedItems[i].key);
    }
    
    if (kDebugMode) {
      print('🗑️ [Session Cache] Evicted $itemsToRemove least used items');
    }
  }

  /// Evict oldest images when image cache is full
  static Future<void> _evictOldestImages() async {
    final imageKeys = <String>[];
    for (final key in _sessionCache.keys) {
      if (key.startsWith(_recipeImagesCategory) || key.startsWith(_ingredientImagesCategory)) {
        imageKeys.add(key);
      }
    }
    
    if (imageKeys.isEmpty) return;
    
    // Sort by timestamp (oldest first)
    imageKeys.sort((a, b) {
      final timeA = _cacheTimestamps[a] ?? DateTime.now();
      final timeB = _cacheTimestamps[b] ?? DateTime.now();
      return timeA.compareTo(timeB);
    });
    
    // Remove oldest 25% of images
    final itemsToRemove = (imageKeys.length * 0.25).ceil();
    for (int i = 0; i < itemsToRemove && i < imageKeys.length; i++) {
      _removeCacheItem(imageKeys[i]);
    }
    
    if (kDebugMode) {
      print('🗑️ [Session Cache] Evicted $itemsToRemove oldest images');
    }
  }

  /// Remove item from cache
  static void _removeCacheItem(String key) {
    _sessionCache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheAccessCounts.remove(key);
  }

  /// Clear all session cache (called on app close)
  static Future<void> clearSessionCache() async {
    if (kDebugMode) {
      print('🗑️ [Session Cache] Clearing session cache...');
      print('📊 [Session Cache] Items cleared: ${_sessionCache.length}');
      print('🖼️ [Session Cache] Images cleared: ${_getImageCacheSize()}');
      print('⏱️ [Session Cache] Session duration: ${DateTime.now().difference(_sessionStartTime ?? DateTime.now()).inMinutes} minutes');
    }
    
    _sessionCache.clear();
    _cacheTimestamps.clear();
    _cacheAccessCounts.clear();
    _sessionStartTime = null;
    _isInitialized = false;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final sessionDuration = _sessionStartTime != null 
        ? now.difference(_sessionStartTime!)
        : Duration.zero;
    
    return {
      'service': 'Session Cache Service',
      'is_initialized': _isInitialized,
      'session_start_time': _sessionStartTime?.toIso8601String(),
      'session_duration_minutes': sessionDuration.inMinutes,
      'total_cache_items': _sessionCache.length,
      'image_cache_items': _getImageCacheSize(),
      'recipe_images': _getCategoryCount(_recipeImagesCategory),
      'ingredient_images': _getCategoryCount(_ingredientImagesCategory),
      'recipe_details': _getCategoryCount(_recipeDetailsCategory),
      'cooking_steps': _getCategoryCount(_cookingStepsCategory),
      'text_data': _getCategoryCount(_textDataCategory),
      'max_cache_size': _maxCacheSize,
      'max_image_cache_size': _maxImageCacheSize,
      'session_timeout_hours': _sessionTimeout.inHours,
    };
  }

  /// Get count of items in specific category
  static int _getCategoryCount(String category) {
    int count = 0;
    for (final key in _sessionCache.keys) {
      if (key.startsWith('${category}_')) {
        count++;
      }
    }
    return count;
  }

  /// Preload commonly used data into session cache
  static Future<void> preloadCommonData({
    List<String>? recipeNames,
    List<String>? ingredientNames,
    List<String>? textKeys,
  }) async {
    await initialize();
    
    if (kDebugMode) {
      print('🔄 [Session Cache] Preloading common data...');
    }
    
    // This would be called with actual data from other services
    // For now, it's a placeholder for the preloading logic
    
    if (kDebugMode) {
      print('✅ [Session Cache] Preloading completed');
    }
  }

  /// Check if session is still valid
  static bool isSessionValid() {
    if (!_isInitialized || _sessionStartTime == null) return false;
    
    final now = DateTime.now();
    final sessionAge = now.difference(_sessionStartTime!);
    
    return sessionAge < const Duration(hours: 6); // Max session duration
  }

  /// Get most frequently accessed items
  static List<Map<String, dynamic>> getMostAccessedItems({int limit = 10}) {
    final sortedItems = _cacheAccessCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedItems.take(limit).map((entry) => {
      'key': entry.key,
      'access_count': entry.value,
      'timestamp': _cacheTimestamps[entry.key]?.toIso8601String(),
      'data_size': _sessionCache[entry.key].toString().length,
    }).toList();
  }
}
