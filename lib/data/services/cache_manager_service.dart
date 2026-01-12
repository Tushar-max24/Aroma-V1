// lib/data/services/cache_manager_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'cache_database_service.dart';
import '../repositories/recipe_cache_repository.dart';

class CacheManagerService {
  static bool _initialized = false;
  static Timer? _cleanupTimer;

  /// Initialize the cache system
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize database
      await CacheDatabaseService.database;
      
      // Start periodic cleanup (every 24 hours)
      _startPeriodicCleanup();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('✅ Cache Manager initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cache Manager initialization failed: $e');
      }
      rethrow;
    }
  }

  /// Start periodic cleanup of expired cache entries
  static void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 24),
      (_) => _performCleanup(),
    );
  }

  /// Perform cleanup of expired cache entries
  static Future<void> _performCleanup() async {
    try {
      await RecipeCacheRepository.clearExpiredCache();
      if (kDebugMode) {
        print('🗑️ Cache cleanup completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cache cleanup failed: $e');
      }
    }
  }

  /// Clear all cache data
  static Future<void> clearAllCache() async {
    try {
      await RecipeCacheRepository.clearAllCache();
      if (kDebugMode) {
        print('🗑️ All cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to clear cache: $e');
      }
      rethrow;
    }
  }

  /// Get cache statistics
  static Future<Map<String, int>> getCacheStats() async {
    try {
      final db = await CacheDatabaseService.database;
      
      final recipeDetailsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${CacheDatabaseService.recipeDetailTable}')
      ) ?? 0;
      
      final cookingStepsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${CacheDatabaseService.cookingStepTable}')
      ) ?? 0;
      
      final generatedRecipesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${CacheDatabaseService.generatedRecipeTable}')
      ) ?? 0;
      
      return {
        'recipeDetails': recipeDetailsCount,
        'cookingSteps': cookingStepsCount,
        'generatedRecipes': generatedRecipesCount,
        'total': recipeDetailsCount + cookingStepsCount + generatedRecipesCount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get cache stats: $e');
      }
      return {
        'recipeDetails': 0,
        'cookingSteps': 0,
        'generatedRecipes': 0,
        'total': 0,
      };
    }
  }

  /// Close cache manager and cleanup resources
  static Future<void> dispose() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    
    await CacheDatabaseService.closeDatabase();
    _initialized = false;
    
    if (kDebugMode) {
      print('✅ Cache Manager disposed');
    }
  }

  /// Check if cache manager is initialized
  static bool get isInitialized => _initialized;

  /// Force cleanup of expired entries
  static Future<void> forceCleanup() async {
    await _performCleanup();
  }
}
