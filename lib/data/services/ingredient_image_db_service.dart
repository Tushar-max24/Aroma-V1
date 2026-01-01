import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/ingredient_image_model.dart';

class IngredientImageDBService {
  static Database? _database;
  static const String _tableName = 'ingredient_images';
  static const int _dbVersion = 1;

  static Future<void> initialize() async {
    if (_database != null) return;
    
    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, 'ingredient_images.db');
      
      _database = await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      if (kDebugMode) {
        print('✅ Ingredient image database initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize database: $e');
      }
      rethrow;
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        ingredient_name TEXT UNIQUE NOT NULL,
        local_path TEXT NOT NULL,
        image_url TEXT,
        created_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL
      )
    ''');
    
    // Create index for faster lookups
    await db.execute('CREATE INDEX idx_ingredient_name ON $_tableName(ingredient_name)');
    
    if (kDebugMode) {
      print('✅ Database table created');
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades if needed in future versions
    if (kDebugMode) {
      print('🔄 Database upgraded from $oldVersion to $newVersion');
    }
  }

  static Future<IngredientImageModel?> getCachedImage(String ingredientName) async {
    await initialize();
    
    if (kDebugMode) {
      print('🔍 Checking DB for cached image: $ingredientName');
    }
    
    try {
      final maps = await _database!.query(
        _tableName,
        where: 'ingredient_name = ?',
        whereArgs: [ingredientName.toLowerCase().trim()],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final map = maps.first;
        final model = IngredientImageModel(
          id: map['id'].toString(),
          ingredientName: map['ingredient_name'] as String,
          localPath: map['local_path'] as String,
          imageUrl: map['image_url'] as String? ?? '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
          lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed'] as int),
        );

        // Update last accessed time
        await updateLastAccessed(ingredientName);
        
        if (kDebugMode) {
          print('✅ Found cached image in DB for: $ingredientName');
        }
        
        return model;
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cached image from DB: $e');
      }
      return null;
    }
  }

  static Future<void> cacheImage(IngredientImageModel model) async {
    await initialize();
    
    try {
      final data = {
        'id': model.id,
        'ingredient_name': model.ingredientName.toLowerCase().trim(),
        'local_path': model.localPath,
        'image_url': model.imageUrl,
        'created_at': model.createdAt.millisecondsSinceEpoch,
        'last_accessed': model.lastAccessed.millisecondsSinceEpoch,
      };

      await _database!.insert(
        _tableName,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (kDebugMode) {
        print('✅ Cached image in DB for: ${model.ingredientName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error caching image in DB: $e');
      }
    }
  }

  static Future<void> updateLastAccessed(String ingredientName) async {
    await initialize();
    
    try {
      await _database!.update(
        _tableName,
        {'last_accessed': DateTime.now().millisecondsSinceEpoch},
        where: 'ingredient_name = ?',
        whereArgs: [ingredientName.toLowerCase().trim()],
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating last accessed time: $e');
      }
    }
  }

  static Future<void> removeCachedImage(String ingredientName) async {
    await initialize();
    
    try {
      await _database!.delete(
        _tableName,
        where: 'ingredient_name = ?',
        whereArgs: [ingredientName.toLowerCase().trim()],
      );

      if (kDebugMode) {
        print('🗑️ Removed cached image from DB for: $ingredientName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing cached image from DB: $e');
      }
    }
  }

  static Future<List<IngredientImageModel>> getAllCachedImages() async {
    await initialize();
    
    try {
      final maps = await _database!.query(
        _tableName,
        orderBy: 'last_accessed DESC',
      );

      return maps.map((map) => IngredientImageModel(
        id: map['id'].toString(),
        ingredientName: map['ingredient_name'] as String,
        localPath: map['local_path'] as String,
        imageUrl: map['image_url'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        lastAccessed: DateTime.fromMillisecondsSinceEpoch(map['last_accessed'] as int),
      )).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting all cached images: $e');
      }
      return [];
    }
  }

  static Future<void> clearOldCache({Duration maxAge = const Duration(days: 30)}) async {
    await initialize();
    
    try {
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      
      await _database!.delete(
        _tableName,
        where: 'last_accessed < ?',
        whereArgs: [cutoffTime],
      );

      if (kDebugMode) {
        print('🗑️ Cleared old cache entries older than ${maxAge.inDays} days');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing old cache: $e');
      }
    }
  }

  static Future<int> getCacheSize() async {
    await initialize();
    
    try {
      final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting cache size: $e');
      }
      return 0;
    }
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
