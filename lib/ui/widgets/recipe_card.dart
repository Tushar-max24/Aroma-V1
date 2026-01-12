import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/add_ingredients/capture_preview_screen.dart';
import '../screens/recipe_detail/recipe_detail_screen.dart';
import '../../data/models/recipe_model.dart';
import '../../state/home_provider.dart';
import '../../core/enums/scan_mode.dart';
import 'cached_image.dart'; // Added import statement


class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, this.isActive = false});

  final RecipeModel recipe;
  final bool isActive;

  // Navigate to recipe detail screen
  void _navigateToRecipeDetail(BuildContext context, RecipeModel recipe) {
    // Use the full backend data if available, otherwise create basic structure
    final fullRecipeData = recipe.fullRecipeData ?? {
      'description': recipe.description ?? '',
      'nutrition': {
        'calories': recipe.calories,
        'protein': 0,
        'carbs': 0,
        'fats': 0,
      },
      'cooking_steps': recipe.instructions.map((instruction) => {
        'instruction': instruction,
        'ingredients': [],
        'tips': [],
      }).toList(),
      'tags': {
        'cookware': [],
      },
      'ingredients': recipe.ingredients.map((ingredient) => {
        'item': ingredient,
        'quantity': '1',
      }).toList(),
    };

    // Convert string ingredients to Map format for RecipeDetailScreen
    final ingredientMaps = (fullRecipeData['ingredients'] as List<dynamic>?)
        ?.map((ing) => ing as Map<String, dynamic>)
        .toList() ?? 
        recipe.ingredients.map((ingredient) => {
          'item': ingredient,
          'quantity': '1',
        }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(
          image: recipe.image,
          title: recipe.title,
          ingredients: ingredientMaps,
          cuisine: recipe.cuisine,
          cookTime: recipe.cookTime,
          servings: recipe.servings,
          fullRecipeData: fullRecipeData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 2/3, // 2:3 aspect ratio for all cards
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Background image from backend URL with caching
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedImage(
                imageUrl: recipe.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: Container(color: Colors.grey[300]),
              ),
            ),

            // Top-left badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFFD54F) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "Today's special",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.black : Colors.black87,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  recipe.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Gen-AI',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.restaurant,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.cuisine,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookTime} min',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToRecipeDetail(context, recipe);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text('Cook now'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<HomeProvider>().toggleSaved(recipe.id);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              recipe.isSaved ? Colors.redAccent : Colors.white,
                          side: BorderSide(
                            color: recipe.isSaved
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              recipe.isSaved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: recipe.isSaved
                                  ? Colors.redAccent
                                  : Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: recipe.isSaved
                                    ? Colors.redAccent
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

