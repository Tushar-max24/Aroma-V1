// lib/data/services/app_initialization_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'cache_manager_service.dart';
import 'cache_database_service.dart';
import '../repositories/recipe_cache_repository.dart';
import '../../state/pantry_state.dart';
import '../../state/home_provider.dart';
import '../services/gemini_recipe_service.dart';
import '../services/preference_api_service.dart';

class AppInitializationService {
  static bool _initialized = false;
  static final Map<String, dynamic> _initStats = {};

  /// Initialize all app services during splash screen
  static Future<Map<String, dynamic>> initializeDuringSplash() async {
    if (_initialized) {
      return _initStats;
    }

    final stopwatch = Stopwatch()..start();
    _initStats.clear();

    try {
      debugPrint('🚀 Starting app initialization...');

      // Phase 1: Critical Services (0-2 seconds)
      await _initializeCriticalServices();
      
      // Phase 2: Cache Optimization (2-5 seconds)
      await _optimizeCacheDuringSplash();
      
      // Phase 3: Preload Common Data (5-8 seconds)
      await _preloadCommonData();
      
      // Phase 4: Background Tasks (8-10+ seconds)
      _startBackgroundTasks();

      stopwatch.stop();
      _initStats['totalTime'] = stopwatch.elapsedMilliseconds;
      _initStats['success'] = true;
      _initialized = true;

      debugPrint('✅ App initialization completed in ${stopwatch.elapsedMilliseconds}ms');
      return _initStats;

    } catch (e, stackTrace) {
      stopwatch.stop();
      _initStats['totalTime'] = stopwatch.elapsedMilliseconds;
      _initStats['success'] = false;
      _initStats['error'] = e.toString();
      
      debugPrint('❌ App initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return _initStats;
    }
  }

  /// Phase 1: Initialize critical services that must complete before app starts
  static Future<void> _initializeCriticalServices() async {
    final phaseStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('📋 Phase 1: Critical Services');
      
      // 1. Cache Manager (already done in main.dart, but verify)
      if (!CacheManagerService.isInitialized) {
        await CacheManagerService.initialize();
      }
      
      // 2. Get initial cache statistics
      final cacheStats = await CacheManagerService.getCacheStats();
      _initStats['initialCacheStats'] = cacheStats;
      
      phaseStopwatch.stop();
      _initStats['phase1Time'] = phaseStopwatch.elapsedMilliseconds;
      
      debugPrint('✅ Phase 1 completed in ${phaseStopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Cache stats: ${cacheStats['total']} items cached');
      
    } catch (e) {
      phaseStopwatch.stop();
      _initStats['phase1Time'] = phaseStopwatch.elapsedMilliseconds;
      _initStats['phase1Error'] = e.toString();
      debugPrint('❌ Phase 1 failed: $e');
      rethrow;
    }
  }

  /// Phase 2: Optimize cache and perform cleanup during splash
  static Future<void> _optimizeCacheDuringSplash() async {
    final phaseStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('🧹 Phase 2: Cache Optimization');
      
      // 1. Clean up expired cache entries
      await CacheManagerService.forceCleanup();
      _initStats['cleanupPerformed'] = true;
      
      // 2. Get cache statistics after cleanup
      final cleanedStats = await CacheManagerService.getCacheStats();
      _initStats['cleanedCacheStats'] = cleanedStats;
      
      // 3. Check database health and optimize if needed
      final db = await CacheDatabaseService.database;
      await db.execute('VACUUM'); // Optimize database file size
      
      phaseStopwatch.stop();
      _initStats['phase2Time'] = phaseStopwatch.elapsedMilliseconds;
      
      debugPrint('✅ Phase 2 completed in ${phaseStopwatch.elapsedMilliseconds}ms');
      debugPrint('🗑️ Cache cleanup completed');
      
    } catch (e) {
      phaseStopwatch.stop();
      _initStats['phase2Time'] = phaseStopwatch.elapsedMilliseconds;
      _initStats['phase2Error'] = e.toString();
      debugPrint('❌ Phase 2 failed: $e');
      // Don't rethrow - cache optimization failures shouldn't stop app
    }
  }

  /// Phase 3: Preload commonly accessed data
  static Future<void> _preloadCommonData() async {
    final phaseStopwatch = Stopwatch()..start();
    
    try {
      debugPrint('⚡ Phase 3: Preloading Common Data');
      
      int preloadedItems = 0;
      
      // 1. Preload popular recipe details (if any cached)
      final popularRecipes = [
        'Chicken Curry',
        'Pasta',
        'Salad',
        'Soup',
        'Rice',
        'Bread',
        'Eggs',
        'Vegetables'
      ];
      
      for (final recipeName in popularRecipes) {
        try {
          final cached = await RecipeCacheRepository.getCachedRecipeDetails(recipeName);
          if (cached != null) {
            preloadedItems++;
            debugPrint('📖 Preloaded cached recipe: $recipeName');
          }
        } catch (e) {
          // Ignore individual preload failures
        }
      }
      
      // 2. Preload cache statistics for faster access
      final finalStats = await CacheManagerService.getCacheStats();
      _initStats['finalCacheStats'] = finalStats;
      
      // 3. Warm up Gemini service connection
      GeminiRecipeService.initialize();
      
      phaseStopwatch.stop();
      _initStats['phase3Time'] = phaseStopwatch.elapsedMilliseconds;
      _initStats['preloadedItems'] = preloadedItems;
      
      debugPrint('✅ Phase 3 completed in ${phaseStopwatch.elapsedMilliseconds}ms');
      debugPrint('📦 Preloaded $preloadedItems cached items');
      
    } catch (e) {
      phaseStopwatch.stop();
      _initStats['phase3Time'] = phaseStopwatch.elapsedMilliseconds;
      _initStats['phase3Error'] = e.toString();
      debugPrint('❌ Phase 3 failed: $e');
      // Don't rethrow - preload failures shouldn't stop app
    }
  }

  /// Phase 4: Start background tasks that continue after splash
  static void _startBackgroundTasks() {
    debugPrint('🔄 Phase 4: Starting Background Tasks');
    
    // 1. Periodic cache statistics monitoring
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      try {
        final stats = await CacheManagerService.getCacheStats();
        if (kDebugMode) {
          debugPrint('📊 Cache stats update: ${stats['total']} items');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Cache stats update failed: $e');
        }
      }
    });
    
    // 2. Background cache warming for predicted content
    Timer.periodic(const Duration(hours: 1), (timer) async {
      try {
        await _warmupPredictedContent();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Background warmup failed: $e');
        }
      }
    });
    
    _initStats['backgroundTasksStarted'] = true;
    debugPrint('✅ Background tasks started');
  }

  /// Warm up cache with predicted content
  static Future<void> _warmupPredictedContent() async {
    // This could be enhanced with ML predictions based on user behavior
    final predictedRecipes = [
      'Quick Breakfast',
      'Lunch Special',
      'Dinner Classic',
      'Healthy Snack'
    ];
    
    for (final recipe in predictedRecipes) {
      try {
        // Check if already cached
        final cached = await RecipeCacheRepository.getCachedRecipeDetails(recipe);
        if (cached == null) {
          // Could pre-fetch in background (but don't block UI)
          debugPrint('🔮 Predicted recipe not cached: $recipe');
        }
      } catch (e) {
        // Ignore individual warmup failures
      }
    }
  }

  /// Get initialization statistics
  static Map<String, dynamic> get initStats => Map.from(_initStats);

  /// Check if initialization is complete
  static bool get isInitialized => _initialized;

  /// Reset initialization state (for testing)
  static void reset() {
    _initialized = false;
    _initStats.clear();
  }

  /// Get recommended splash duration based on initialization progress
  static Duration getRecommendedSplashDuration() {
    if (!_initStats.containsKey('totalTime')) {
      return const Duration(seconds: 10); // Default
    }
    
    final totalTime = _initStats['totalTime'] as int;
    final baseDuration = Duration(milliseconds: totalTime);
    
    // Add 1-2 seconds buffer for smooth transition
    return baseDuration + const Duration(seconds: 2);
  }
}
