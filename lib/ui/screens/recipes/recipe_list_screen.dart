import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../recipe_detail/recipe_detail_screen.dart';
import '../../../widgets/cached_image.dart';
import '../../../data/repositories/recipe_cache_repository.dart';
import '../../../data/services/smart_recipe_list_preloader_service.dart';

class RecipeListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Map<String, dynamic> preferences;

  const RecipeListScreen({
    super.key,
    required this.ingredients,
    required this.preferences,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  final List<_RecipeData> _allRecipes = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPreloading = false;

  int _visibleCount = 3;
  final Set<int> _likedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  // Generate recipe images in background using /generate-image API
  Future<void> _generateRecipeImagesInBackground(List<_RecipeData> recipes) async {
    const String imageApiUrl = 'http://3.108.110.151:5001/generate-image';
    
    for (int i = 0; i < recipes.length; i++) {
      final recipe = recipes[i];
      
      // Skip if recipe already has a valid image (not fallback)
      if (recipe.image.isNotEmpty && 
          !recipe.image.contains('pexels.com') && 
          !recipe.image.contains('1640777')) {
        debugPrint("⏭️ [Recipe List] Skipping ${recipe.title} - already has image: ${recipe.image.substring(0, 50)}...");
        continue;
      }
      
      try {
        debugPrint("🖼️ [Recipe List] Starting image generation for: ${recipe.title}");
        
        final response = await http.post(
          Uri.parse(imageApiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'dish_name': recipe.title, // Use the exact format you specified
          }),
        ).timeout(const Duration(seconds: 30)); // Add timeout
        
        debugPrint("📡 [Recipe List] Image API response status: ${response.statusCode}");
        
        if (response.statusCode == 200) {
          final Map<String, dynamic> imageData = jsonDecode(response.body);
          debugPrint("📦 [Recipe List] Image API response: ${imageData.keys.toList()}");
          debugPrint("📄 [Recipe List] Full response body: ${response.body}");
          
          String? imageUrl;
          
          // Handle different response formats
          if (imageData.containsKey('image_url')) {
            imageUrl = imageData['image_url'].toString();
          } else if (imageData.containsKey('results') && imageData['results'] is Map) {
            final results = imageData['results'] as Map<String, dynamic>;
            
            // Check if results has the recipe name as a key (new format)
            if (results.containsKey(recipe.title)) {
              final recipeData = results[recipe.title] as Map<String, dynamic>;
              if (recipeData.containsKey('image_url')) {
                imageUrl = recipeData['image_url'].toString();
              } else if (recipeData.containsKey('url')) {
                imageUrl = recipeData['url'].toString();
              } else if (recipeData.containsKey('image')) {
                imageUrl = recipeData['image'].toString();
              }
            }
            // Check direct fields in results (old format)
            else if (results.containsKey('image_url')) {
              imageUrl = results['image_url'].toString();
            } else if (results.containsKey('url')) {
              imageUrl = results['url'].toString();
            } else if (results.containsKey('image')) {
              imageUrl = results['image'].toString();
            }
          } else if (imageData.containsKey('url')) {
            imageUrl = imageData['url'].toString();
          } else if (imageData.containsKey('image')) {
            imageUrl = imageData['image'].toString();
          }
          
          if (imageUrl != null && imageUrl.isNotEmpty) {
            debugPrint("🔗 [Recipe List] Raw image URL: $imageUrl");
            
            // Ensure HTTPS for S3 URLs
            if (imageUrl.startsWith('http://') && imageUrl.contains('s3')) {
              imageUrl = imageUrl.replaceFirst('http://', 'https://');
              debugPrint("🔒 [Recipe List] Converted S3 URL to HTTPS: $imageUrl");
            }
            
            // Update recipe with generated image
            recipes[i].image = imageUrl;
            debugPrint("✅ [Recipe List] Image generated for: ${recipe.title}");
            
            // Trigger UI update to show the new image
            if (mounted) {
              setState(() {});
            }
            
            // Add delay between requests to avoid rate limiting
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            debugPrint("❌ [Recipe List] No image URL found in response for: ${recipe.title}");
            debugPrint("📄 [Recipe List] Available keys: ${imageData.keys.toList()}");
          }
        } else {
          debugPrint("❌ [Recipe List] Image generation failed for: ${recipe.title} - ${response.statusCode}");
          debugPrint("📄 [Recipe List] Error response: ${response.body}");
        }
      } catch (e) {
        debugPrint("❌ [Recipe List] Image generation exception for: ${recipe.title} - $e");
        
        // Continue with next recipe even if current one fails
        continue;
      }
    }
    
    debugPrint("🏁 [Recipe List] Image generation completed for ${recipes.length} recipes");
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _allRecipes.clear();
    });

    try {
      // Fetch recipes directly from backend (no cache)
      final response = await RecipeCacheRepository.getGeneratedRecipes(
        widget.preferences,
        widget.ingredients,
      );
      
      if (response != null) {
        final recipeList = response.recipes;
        print('📋 Backend returned ${recipeList.length} recipes');
        
        // Create UI elements from backend data
        for (var item in recipeList) {
          final recipeTitle = item["recipe_name"] ?? item["Dish"] ?? "Unknown Dish";
          
          // Extract image URL from backend response
          String? recipeImageUrl;
          if (item["recipe_image_url"] != null) {
            recipeImageUrl = item["recipe_image_url"];
          } else if (item["image"] != null) {
            if (item["image"] is String) {
              recipeImageUrl = item["image"];
            } else if (item["image"] is Map) {
              recipeImageUrl = item["image"]["image_url"]?.toString() ?? 
                             item["image"]["url"]?.toString();
            }
          } else if (item["Image"] != null && item["Image"] is Map) {
            recipeImageUrl = item["Image"]["image_url"]?.toString() ?? 
                           item["Image"]["url"]?.toString();
          }
          
          debugPrint("🖼️ Found image in recipe data for $recipeTitle: $recipeImageUrl");
          
          final recipe = _RecipeData(
            image: recipeImageUrl ?? "",
            title: recipeTitle,
            cuisine: widget.preferences['cuisine'] ?? "",
            time: "${widget.preferences['time'] ?? 30} min",
            fullRecipeData: item, // Store complete backend recipe data
          );

          _allRecipes.add(recipe);
        }

        // Start background image generation for recipes without images
        _generateRecipeImagesInBackground(_allRecipes);

        // Start smart preloading in background after UI is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startSmartPreloading();
        });

        setState(() {
          _visibleCount = _allRecipes.length >= 3 ? 3 : _allRecipes.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Start smart preloading of all recipe data
  Future<void> _startSmartPreloading() async {
    if (_allRecipes.isEmpty) return;
    
    setState(() {
      _isPreloading = true;
    });

    try {
      if (kDebugMode) {
        print('🚀 [Recipe List Screen] Starting smart preloading for ${_allRecipes.length} recipes');
      }

      // Use smart recipe list preloader service
      final preloadResult = await SmartRecipeListPreloaderService.preloadRecipeDataBeforeNavigation(
        recipes: _allRecipes.map((r) => r.fullRecipeData).toList(),
        preferences: widget.preferences,
        availableIngredients: widget.ingredients,
      );

      if (kDebugMode) {
        print('✅ [Recipe List Screen] Smart preloading completed');
        print('📊 [Recipe List Screen] Preloaded recipes: ${preloadResult['preloadedRecipes']}');
        print('🥘 [Recipe List Screen] Preloaded ingredients: ${preloadResult['preloadedIngredients']}');
        print('🖼️ [Recipe List Screen] Cached images: ${preloadResult['cachedImages']}');
        print('⏱️ [Recipe List Screen] Preloading time: ${preloadResult['totalTime']}ms');
      }

    } catch (e) {
      if (kDebugMode) {
        print('❌ [Recipe List Screen] Smart preloading failed: $e');
      }
    } finally {
      setState(() {
        _isPreloading = false;
      });
    }
  }

  void _loadMore() {
    setState(() {
      _visibleCount =
          (_visibleCount + 2).clamp(0, _allRecipes.length);
    });
  }

  void _toggleLike(int index) {
    setState(() {
      _likedIndices.contains(index)
          ? _likedIndices.remove(index)
          : _likedIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.15)),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              "Recipes for you",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
            ),
            const SizedBox(height: 28),

            // Smart preloading indicator
            if (_isPreloading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Smart preloading recipes...',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            if (_isPreloading)
              const SizedBox(height: 16)
            else
              const SizedBox(height: 28),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_hasError)
              const Center(child: Text("Error loading recipes"))
            else
              Column(
                children: [
                  for (int i = 0;
                      i < _visibleCount && i < _allRecipes.length;
                      i++) ...[
                    _RecipeCard(
                      data: _allRecipes[i],
                      isLiked: _likedIndices.contains(i),
                      onToggleLike: () => _toggleLike(i),
                      ingredients: widget.ingredients,
                      preferences: widget.preferences,
                    ),
                    const SizedBox(height: 30),
                  ],

                  // ===============================
                  // LOAD MORE
                  // ===============================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _visibleCount < _allRecipes.length
                          ? _loadMore
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Load more recipes',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===============================
                  // SHOW ALL CATEGORIES
                  // ===============================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'Show All Categories',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ===============================
                  // HELP US IMPROVE
                  // ===============================
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      color: const Color(0xFFFFF1EA),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.support_agent, size: 48),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            "Not what you're looking for?\nHelp us improve →",
                            style: TextStyle(
                              fontSize:16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// MODEL
// =====================================================================
class _RecipeData {
  String image;
  final String title;
  final String cuisine;
  final String time;
  final Map<String, dynamic> fullRecipeData; // Store complete backend data

  _RecipeData({
    required this.image,
    required this.title,
    required this.cuisine,
    required this.time,
    required this.fullRecipeData,
  });
}

// =====================================================================
// RECIPE CARD
// =====================================================================
class _RecipeCard extends StatelessWidget {
  final _RecipeData data;
  final bool isLiked;
  final VoidCallback onToggleLike;
  final List<Map<String, dynamic>> ingredients; // ✅ ADD THIS
  final Map<String, dynamic> preferences;  // Add this line

  const _RecipeCard({
    required this.data,
    required this.isLiked,
    required this.onToggleLike,
    required this.ingredients, // ✅ ADD THIS
    required this.preferences,  // Add this line
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 470,
        child: Stack(
          children: [
            Positioned.fill(
              child: data.image.isNotEmpty
                  ? CachedImage(
                      imageUrl: data.image,
                      fit: BoxFit.cover,
                      errorWidget: _loadingPlaceholder(),
                    )
                  : _loadingPlaceholder(),
            ),

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black26,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _infoIcon(Icons.restaurant, data.cuisine),
                      const SizedBox(width: 14),
                      _infoIcon(Icons.access_time, data.time),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
  child: GestureDetector(
    onTap: () {
      // Check if recipe is preloaded for instant navigation
      final preloadedRecipe = SmartRecipeListPreloaderService.getPreloadedRecipe(data.title);
      
      if (kDebugMode) {
        print('🔄 [Recipe List Screen] Navigating to recipe: ${data.title}');
        print('🏷️ [Recipe List Screen] Recipe preloaded: ${preloadedRecipe != null}');
        if (preloadedRecipe != null) {
          print('📦 [Recipe List Screen] Using preloaded data with keys: ${preloadedRecipe.keys.toList()}');
        }
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(
            image: data.image,
            title: data.title,
            ingredients: ingredients, // ✅ pass scan data
            cuisine: preferences["cuisine"]?.toString() ?? "Indian",
            cookTime: preferences["time"]?.toString() ?? "30m",
            servings: int.tryParse(preferences["servings"]?.toString() ?? "4") ?? 4,
            fullRecipeData: preloadedRecipe ?? data.fullRecipeData, // ✅ Use preloaded data if available
          ),
        ),
      );
    },
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Cook now',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    ),
  ),
),

                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onToggleLike,
                        child: Container(
                          height: 52,
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white70),
                            color: Colors.white.withOpacity(0.22),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: const Color(0xFFFF8FA7),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
            )
          ],
        ),
      ),
    );
  }
}

Widget _infoIcon(IconData icon, String text) {
  return Row(
    children: [
      Icon(icon, size: 15, color: Colors.white),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ],
  );
}

Widget _loadingPlaceholder() {
  return Container(
    color: const Color(0xFFF4F4F4),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(Color(0xFFFF6A45)),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Preparing your recipe…',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    ),
  );
}

