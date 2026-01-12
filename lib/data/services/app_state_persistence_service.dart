import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'smart_splash_recipe_cache_service.dart';
import 'smart_recipe_list_preloader_service.dart';
import 'enhanced_ingredient_image_service.dart';
import 'enhanced_recipe_image_service.dart';

class AppStatePersistenceService {
  static bool _isInitialized = false;
  static SharedPreferences? _prefs;
  
  // State keys
  static const String _appStateKey = 'app_state';
  static const String _lastActiveTimeKey = 'last_active_time';
  static const String _cachedRecipesKey = 'cached_recipes';
  static const String _cachedIngredientsKey = 'cached_ingredients';
  static const String _splashStateKey = 'splash_state';
  static const String _preloadedDataKey = 'preloaded_data';
  
  // App lifecycle state
  static bool _isAppInBackground = false;
  static DateTime? _lastActiveTime;
  static Map<String, dynamic> _appState = {};

  /// Initialize the service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      
      // Load persisted state
      await _loadPersistedState();
      
      if (kDebugMode) {
        print('✅ App State Persistence Service initialized');
        print('📊 [AppState] Last active: $_lastActiveTime');
        print('📦 [AppState] Cached recipes: ${_appState['cached_recipes_count'] ?? 0}');
        print('🥘 [AppState] Cached ingredients: ${_appState['cached_ingredients_count'] ?? 0}');
      }
    }
  }

  /// Load persisted state from SharedPreferences
  static Future<void> _loadPersistedState() async {
    try {
      // Load last active time
      final lastActiveTimeStr = _prefs?.getString(_lastActiveTimeKey);
      if (lastActiveTimeStr != null) {
        _lastActiveTime = DateTime.parse(lastActiveTimeStr);
      }

      // Load app state
      final appStateStr = _prefs?.getString(_appStateKey);
      if (appStateStr != null) {
        _appState = jsonDecode(appStateStr);
      }

      // Load preloaded data if recent
      if (_shouldRestorePreloadedData()) {
        await _restorePreloadedData();
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error loading persisted state: $e');
      }
    }
  }

  /// Check if we should restore preloaded data (within 2 hours)
  static bool _shouldRestorePreloadedData() {
    if (_lastActiveTime == null) return false;
    
    final now = DateTime.now();
    final timeSinceLastActive = now.difference(_lastActiveTime!);
    
    // Restore if less than 2 hours ago
    return timeSinceLastActive.inHours < 2;
  }

  /// Restore preloaded data from persistence
  static Future<void> _restorePreloadedData() async {
    try {
      if (kDebugMode) {
        print('🔄 [AppState] Restoring preloaded data...');
      }

      // Restore cached recipes
      final cachedRecipesStr = _prefs?.getString(_cachedRecipesKey);
      if (cachedRecipesStr != null) {
        final cachedRecipes = jsonDecode(cachedRecipesStr) as Map<String, dynamic>;
        for (final entry in cachedRecipes.entries) {
          SmartSplashRecipeCacheService.splashRecipeCache[entry.key] = entry.value;
        }
        if (kDebugMode) {
          print('📦 [AppState] Restored ${cachedRecipes.length} cached recipes');
        }
      }

      // Restore cached ingredients
      final cachedIngredientsStr = _prefs?.getString(_cachedIngredientsKey);
      if (cachedIngredientsStr != null) {
        final cachedIngredients = jsonDecode(cachedIngredientsStr) as Map<String, dynamic>;
        for (final entry in cachedIngredients.entries) {
          SmartSplashRecipeCacheService.splashIngredientCache[entry.key] = entry.value;
        }
        if (kDebugMode) {
          print('🥘 [AppState] Restored ${cachedIngredients.length} cached ingredients');
        }
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error restoring preloaded data: $e');
      }
    }
  }

  /// Save current state to persistence
  static Future<void> saveState() async {
    try {
      if (_prefs == null) return;

      // Update last active time
      _lastActiveTime = DateTime.now();
      await _prefs!.setString(_lastActiveTimeKey, _lastActiveTime!.toIso8601String());

      // Update app state
      _appState = {
        'last_active_time': _lastActiveTime!.toIso8601String(),
        'cached_recipes_count': SmartSplashRecipeCacheService.splashRecipeCache.length,
        'cached_ingredients_count': SmartSplashRecipeCacheService.splashIngredientCache.length,
        'recipe_list_cache_count': SmartRecipeListPreloaderService.recipeListCache.length,
        'ingredient_list_cache_count': SmartRecipeListPreloaderService.ingredientListCache.length,
        'app_in_background': _isAppInBackground,
      };

      await _prefs!.setString(_appStateKey, jsonEncode(_appState));

      // Save preloaded data for quick restoration
      await _savePreloadedData();

      if (kDebugMode) {
        print('💾 [AppState] State saved successfully');
        print('📊 [AppState] Recipes cached: ${_appState['cached_recipes_count']}');
        print('🥘 [AppState] Ingredients cached: ${_appState['cached_ingredients_count']}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error saving state: $e');
      }
    }
  }

  /// Save preloaded data for quick restoration
  static Future<void> _savePreloadedData() async {
    try {
      // Save splash recipe cache
      final splashRecipes = SmartSplashRecipeCacheService.splashRecipeCache;
      if (splashRecipes.isNotEmpty) {
        await _prefs!.setString(_cachedRecipesKey, jsonEncode(splashRecipes));
      }

      // Save splash ingredient cache
      final splashIngredients = SmartSplashRecipeCacheService.splashIngredientCache;
      if (splashIngredients.isNotEmpty) {
        await _prefs!.setString(_cachedIngredientsKey, jsonEncode(splashIngredients));
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error saving preloaded data: $e');
      }
    }
  }

  /// Handle app lifecycle changes
  static void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _isAppInBackground = true;
        if (kDebugMode) {
          print('⏸️ [AppState] App went to background');
        }
        break;
      case AppLifecycleState.resumed:
        _isAppInBackground = false;
        if (kDebugMode) {
          print('▶️ [AppState] App resumed');
        }
        break;
      case AppLifecycleState.detached:
        _isAppInBackground = false;
        if (kDebugMode) {
          print('🔌 [AppState] App detached');
        }
        break;
      default:
        break;
    }
  }

  /// Get smart splash duration based on app state
  static Duration getSmartSplashDuration() {
    if (_lastActiveTime == null) {
      // First time launch - show full splash
      if (kDebugMode) {
        print('🚀 [AppState] First time launch - full splash duration');
      }
      return const Duration(seconds: 8);
    }

    final now = DateTime.now();
    final timeSinceLastActive = now.difference(_lastActiveTime!);

    // Smart splash duration based on time away
    if (timeSinceLastActive.inMinutes < 5) {
      // Very recent - short splash
      if (kDebugMode) {
        print('⚡ [AppState] Recent launch - short splash (${timeSinceLastActive.inMinutes}m ago)');
      }
      return const Duration(seconds: 2);
    } else if (timeSinceLastActive.inMinutes < 30) {
      // Recent - medium splash
      if (kDebugMode) {
        print('🔄 [AppState] Medium splash (${timeSinceLastActive.inMinutes}m ago)');
      }
      return const Duration(seconds: 4);
    } else if (timeSinceLastActive.inHours < 2) {
      // Less than 2 hours - normal splash with restored data
      if (kDebugMode) {
        print('📱 [AppState] Normal splash with restored data (${timeSinceLastActive.inHours}h ago)');
      }
      return const Duration(seconds: 6);
    } else {
      // Long time away - full splash
      if (kDebugMode) {
        print('🌙 [AppState] Long time away - full splash (${timeSinceLastActive.inHours}h ago)');
      }
      return const Duration(seconds: 8);
    }
  }

  /// Check if full initialization is needed
  static bool needsFullInitialization() {
    if (_lastActiveTime == null) {
      return true; // First time launch
    }

    final now = DateTime.now();
    final timeSinceLastActive = now.difference(_lastActiveTime!);

    // Need full initialization if more than 2 hours away
    return timeSinceLastActive.inHours >= 2;
  }

  /// Check if we have cached data
  static bool hasCachedData() {
    return SmartSplashRecipeCacheService.splashRecipeCache.isNotEmpty ||
           SmartSplashRecipeCacheService.splashIngredientCache.isNotEmpty ||
           SmartRecipeListPreloaderService.recipeListCache.isNotEmpty ||
           SmartRecipeListPreloaderService.ingredientListCache.isNotEmpty;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'service': 'App State Persistence Service',
      'last_active_time': _lastActiveTime?.toIso8601String(),
      'app_in_background': _isAppInBackground,
      'splash_recipes_cache': SmartSplashRecipeCacheService.splashRecipeCache.length,
      'splash_ingredients_cache': SmartSplashRecipeCacheService.splashIngredientCache.length,
      'recipe_list_cache': SmartRecipeListPreloaderService.recipeListCache.length,
      'ingredient_list_cache': SmartRecipeListPreloaderService.ingredientListCache.length,
      'total_cached_items': SmartSplashRecipeCacheService.splashRecipeCache.length +
                           SmartSplashRecipeCacheService.splashIngredientCache.length +
                           SmartRecipeListPreloaderService.recipeListCache.length +
                           SmartRecipeListPreloaderService.ingredientListCache.length,
      'needs_full_init': needsFullInitialization(),
      'splash_duration': getSmartSplashDuration().inSeconds,
    };
  }

  /// Clear all persisted state
  static Future<void> clearPersistedState() async {
    try {
      if (_prefs != null) {
        await _prefs!.remove(_appStateKey);
        await _prefs!.remove(_lastActiveTimeKey);
        await _prefs!.remove(_cachedRecipesKey);
        await _prefs!.remove(_cachedIngredientsKey);
        await _prefs!.remove(_splashStateKey);
        await _prefs!.remove(_preloadedDataKey);
      }

      _appState.clear();
      _lastActiveTime = null;

      // Clear memory caches
      SmartSplashRecipeCacheService.clearMemoryCache();
      SmartRecipeListPreloaderService.clearMemoryCache();

      if (kDebugMode) {
        print('🗑️ [AppState] All persisted state cleared');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [AppState] Error clearing persisted state: $e');
      }
    }
  }

  /// Get initialization status
  static Map<String, dynamic> getInitializationStatus() {
    final now = DateTime.now();
    final timeSinceLastActive = _lastActiveTime != null 
        ? now.difference(_lastActiveTime!)
        : Duration.zero;

    return {
      'is_initialized': _isInitialized,
      'last_active_time': _lastActiveTime?.toIso8601String(),
      'time_since_last_active': {
        'days': timeSinceLastActive.inDays,
        'hours': timeSinceLastActive.inHours,
        'minutes': timeSinceLastActive.inMinutes,
        'seconds': timeSinceLastActive.inSeconds,
      },
      'app_in_background': _isAppInBackground,
      'has_cached_data': hasCachedData(),
      'needs_full_init': needsFullInitialization(),
      'smart_splash_duration': getSmartSplashDuration().inSeconds,
    };
  }
}
