// lib/data/services/cache_database_service.dart
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe_cache_model.dart';

class CacheDatabaseService {
  static Database? _database;
  static const String _dbName = 'recipe_cache.db';
  static const int _dbVersion = 1;

  // Table names
  static const String recipeDetailTable = 'recipe_details';
  static const String cookingStepTable = 'cooking_steps';
  static const String generatedRecipeTable = 'generated_recipes';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Recipe details cache table
    await db.execute('''
      CREATE TABLE $recipeDetailTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_name TEXT UNIQUE NOT NULL,
        description TEXT,
        nutrition TEXT,
        cookware TEXT,
        preparation_steps TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Cooking steps cache table
    await db.execute('''
      CREATE TABLE $cookingStepTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_name TEXT NOT NULL,
        step_number INTEGER NOT NULL,
        instruction TEXT,
        tips TEXT,
        ingredients TEXT,
        cached_at TEXT NOT NULL,
        UNIQUE(recipe_name, step_number)
      )
    ''');

    // Generated recipes cache table
    await db.execute('''
      CREATE TABLE $generatedRecipeTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        preference_hash TEXT UNIQUE NOT NULL,
        recipes TEXT,
        recipe_images TEXT,
        cuisine TEXT,
        cached_at TEXT NOT NULL
      )
    ''');

    // Create indexes for faster lookups
    await db.execute('CREATE INDEX idx_recipe_name ON $recipeDetailTable(recipe_name)');
    await db.execute('CREATE INDEX idx_cooking_recipe_name ON $cookingStepTable(recipe_name)');
    await db.execute('CREATE INDEX idx_preference_hash ON $generatedRecipeTable(preference_hash)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in future versions
  }

  // Recipe Details Cache Methods
  static Future<RecipeDetailCache?> getRecipeDetail(String recipeName) async {
    final db = await database;
    final maps = await db.query(
      recipeDetailTable,
      where: 'recipe_name = ?',
      whereArgs: [recipeName],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return RecipeDetailCache.fromJson({
        'recipe_name': map['recipe_name'],
        'description': map['description'],
        'nutrition': jsonDecode(map['nutrition']?.toString() ?? '{}'),
        'cookware': jsonDecode(map['cookware']?.toString() ?? '[]'),
        'preparation_steps': jsonDecode(map['preparation_steps']?.toString() ?? '[]'),
        'cached_at': map['cached_at'],
      });
    }
    return null;
  }

  static Future<void> cacheRecipeDetail(RecipeDetailCache cache) async {
    final db = await database;
    await db.insert(
      recipeDetailTable,
      {
        'recipe_name': cache.recipeName,
        'description': cache.description,
        'nutrition': jsonEncode(cache.nutrition),
        'cookware': jsonEncode(cache.cookware),
        'preparation_steps': jsonEncode(cache.preparationSteps),
        'cached_at': cache.cachedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Cooking Steps Cache Methods
  static Future<List<CookingStepCache>> getCookingSteps(String recipeName) async {
    final db = await database;
    final maps = await db.query(
      cookingStepTable,
      where: 'recipe_name = ?',
      whereArgs: [recipeName],
      orderBy: 'step_number ASC',
    );

    return maps.map((map) => CookingStepCache.fromJson({
      'recipe_name': map['recipe_name'],
      'step_number': map['step_number'],
      'instruction': map['instruction'],
      'tips': jsonDecode(map['tips']?.toString() ?? '[]'),
      'ingredients': jsonDecode(map['ingredients']?.toString() ?? '[]'),
      'cached_at': map['cached_at'],
    })).toList();
  }

  static Future<void> cacheCookingSteps(List<CookingStepCache> steps) async {
    final db = await database;
    final batch = db.batch();

    for (final step in steps) {
      batch.insert(
        cookingStepTable,
        {
          'recipe_name': step.recipeName,
          'step_number': step.stepNumber,
          'instruction': step.instruction,
          'tips': jsonEncode(step.tips),
          'ingredients': jsonEncode(step.ingredients),
          'cached_at': step.cachedAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Generated Recipes Cache Methods
  static Future<GeneratedRecipeCache?> getGeneratedRecipes(String preferenceHash) async {
    final db = await database;
    final maps = await db.query(
      generatedRecipeTable,
      where: 'preference_hash = ?',
      whereArgs: [preferenceHash],
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return GeneratedRecipeCache.fromJson({
        'preference_hash': map['preference_hash'],
        'recipes': jsonDecode(map['recipes']?.toString() ?? '[]'),
        'recipe_images': jsonDecode(map['recipe_images']?.toString() ?? '{}'),
        'cuisine': map['cuisine'],
        'cached_at': map['cached_at'],
      });
    }
    return null;
  }

  static Future<void> cacheGeneratedRecipes(GeneratedRecipeCache cache) async {
    final db = await database;
    await db.insert(
      generatedRecipeTable,
      {
        'preference_hash': cache.preferenceHash,
        'recipes': jsonEncode(cache.recipes),
        'recipe_images': jsonEncode(cache.recipeImages),
        'cuisine': cache.cuisine,
        'cached_at': cache.cachedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Utility Methods
  static Future<void> clearCache() async {
    final db = await database;
    await db.delete(recipeDetailTable);
    await db.delete(cookingStepTable);
    await db.delete(generatedRecipeTable);
  }

  static Future<void> clearExpiredCache({Duration maxAge = const Duration(hours: 24)}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(maxAge).toIso8601String();

    await db.delete(recipeDetailTable, where: 'cached_at < ?', whereArgs: [cutoffDate]);
    await db.delete(cookingStepTable, where: 'cached_at < ?', whereArgs: [cutoffDate]);
    await db.delete(generatedRecipeTable, where: 'cached_at < ?', whereArgs: [cutoffDate]);
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
