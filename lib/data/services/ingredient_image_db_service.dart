import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ingredient_image_model.dart';

// Temporarily commented out sqlite dependencies for build issues
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as path;
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class IngredientImageDBService {
  // static Database? _database;
  // static const String _tableName = 'ingredient_images';
  // static const int _dbVersion = 1;

  static Future<void> initialize() async {
    // Temporarily disabled for build issues
    if (kDebugMode) {
      print('⚠️ Database service temporarily disabled for build issues');
    }
    return;
  }

  // static Future<void> _onCreate(Database db, int version) async {
//   await db.execute('''
//     CREATE TABLE ingredient_images (
//     CREATE TABLE $_tableName (
//       id TEXT PRIMARY KEY,
//       ingredient_name TEXT UNIQUE NOT NULL,
//       local_path TEXT NOT NULL,
//       image_url TEXT,
//       created_at INTEGER NOT NULL,
//       last_accessed INTEGER NOT NULL
//     )
//   ''');
  
//   // Create index for faster lookups
//   await db.execute('CREATE INDEX idx_ingredient_name ON $_tableName(ingredient_name)');
  
//   if (kDebugMode) {
//     print('✅ Database table created');
//   }
// }

// static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
//   // Handle database upgrades if needed in future versions
//   if (kDebugMode) {
//     print('🔄 Database upgraded from $oldVersion to $newVersion');
//   }
// }

  static Future<IngredientImageModel?> getCachedImage(String ingredientName) async {
    await initialize();
    // Temporarily disabled - always return null
    return null;
  }

  static Future<void> cacheImage(IngredientImageModel model) async {
    await initialize();
    // Temporarily disabled - do nothing
    return;
  }

  static Future<void> updateLastAccessed(String ingredientName) async {
    await initialize();
    // Temporarily disabled - do nothing
    return;
  }

  static Future<void> removeCachedImage(String ingredientName) async {
    await initialize();
    // Temporarily disabled - do nothing
    return;
  }

  static Future<List<IngredientImageModel>> getAllCachedImages() async {
    await initialize();
    // Temporarily disabled - return empty list
    return [];
  }

  static Future<void> clearOldCache({Duration maxAge = const Duration(days: 30)}) async {
    await initialize();
    // Temporarily disabled - do nothing
    return;
  }

  static Future<int> getCacheSize() async {
    await initialize();
    // Temporarily disabled - return 0
    return 0;
  }

  static Future<void> close() async {
    // Temporarily disabled - do nothing
    return;
  }
}
