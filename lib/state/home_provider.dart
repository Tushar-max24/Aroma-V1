import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/home_recipe_service.dart';
import '../data/models/recipe_model.dart';

class HomeProvider extends ChangeNotifier {
  final HomeRecipeService _service = HomeRecipeService();

  bool isLoading = false;
  String? error;

  /// 🔥 UI EXPECTS RecipeModel
  List<RecipeModel> recipes = [];

  // Fallback recipes in case of API failure
  final List<RecipeModel> _fallbackRecipes = [
    RecipeModel(
      id: "f1",
      title: "Masala Dosa",
      cuisine: "Indian",
      cookTime: '15',
      image: "https://images.pexels.com/photos/5560763/pexels-photo-5560763.jpeg",
    ),
    RecipeModel(
      id: "f2",
      title: "Vegetable Upma",
      cuisine: "Indian",
      cookTime: '20',
      image: "https://images.pexels.com/photos/5848490/pexels-photo-5848490.jpeg",
    ),
  ];


  // 🔹 NORMALIZE API RESPONSE → RecipeModel
  List<RecipeModel> _normalizeRecipes(List<dynamic> apiData) {
  return apiData.map<RecipeModel>((item) {
    final Map<String, dynamic> imageObj =
        (item["Image"] ?? {}) as Map<String, dynamic>;

    // 🔹 Parse "12 min" → 12
    final rawTime = item["Cooking Time"]?.toString() ?? "0";
    final cookTime =
        int.tryParse(rawTime.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return RecipeModel(
      id: imageObj["dish_name"]?.toString() ?? UniqueKey().toString(),
      title: imageObj["dish_name"]?.toString() ?? "Unknown Dish",
      cuisine: "Indian",
      cookTime: cookTime.toString(),
      image: imageObj["image_url"]?.toString() ??
          "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg",
      isSaved: false,
    );
  }).toList();
}



  static const String _cachedRecipesKey = 'cached_recipes';
  
  HomeProvider() {
    // Load cached recipes first, then fetch fresh ones
    _loadCachedRecipes().then((_) => loadRecipes());
  }
  
  // Load recipes from cache
  Future<void> _loadCachedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_cachedRecipesKey);
      
      if (cachedData != null) {
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final cachedRecipes = jsonList.map((item) => 
          RecipeModel.fromJson(Map<String, dynamic>.from(item))
        ).toList();
        
        if (cachedRecipes.isNotEmpty) {
          recipes = cachedRecipes;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached recipes: $e');
    }
  }
  
  // Save recipes to cache
  Future<void> _saveRecipesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonData = jsonEncode(recipes.map((r) => r.toJson()).toList());
      await prefs.setString(_cachedRecipesKey, jsonData);
    } catch (e) {
      debugPrint('Error saving recipes to cache: $e');
    }
  }
  
  // Clear cache (for testing or when needed)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedRecipesKey);
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Load recipes for Home screen
  Future<void> loadRecipes() async {
    try {
      // Don't show loading state to prevent UI flicker
      // We already have cached or fallback recipes showing
      
      final data = await _service.generateHomeRecipes();

      if (data.isNotEmpty) {
        final newRecipes = _normalizeRecipes(data);
        if (newRecipes.isNotEmpty) {
          recipes = newRecipes;
          // Save to cache
          await _saveRecipesToCache();
          notifyListeners();
        }
      }
    } catch (e) {
      // Silently handle errors, we already have cached or fallback recipes
      debugPrint(" Home API Error: $e");
      // If we don't have any recipes yet, use fallback
      if (recipes.isEmpty) {
        recipes = List.from(_fallbackRecipes);
        notifyListeners();
      }
    }
  }

  // Save / Unsave (IMMUTABLE SAFE)
  void toggleSaved(String recipeId) {
    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index == -1) return;

    recipes[index] = recipes[index].copyWith(
      isSaved: !recipes[index].isSaved,
    );

    notifyListeners();
  }
}