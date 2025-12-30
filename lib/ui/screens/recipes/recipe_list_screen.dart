// lib/ui/screens/recipes/recipe_list_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../recipe_detail/recipe_detail_screen.dart';
import '../../../widgets/cached_image.dart'; // Add this line


// =====================================================================
// 🔥 IN-MEMORY IMAGE CACHE
// =====================================================================
final Map<String, String> _imageCache = {};

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

  int _visibleCount = 3;
  final Set<int> _likedIndices = {};

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  bool _isValidImageUrl(String url) {
    return url.startsWith("http://") || url.startsWith("https://");
  }

  Future<String?> _fetchDishImage(String dishName) async {
    if (_imageCache.containsKey(dishName)) {
      return _imageCache[dishName];
    }

    try {
      final url =
          Uri.parse("http://3.108.110.151:5001/generate-dish-image");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"dish_name": dishName}),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final imgUrl = decoded["image_url"];

        if (imgUrl is String && _isValidImageUrl(imgUrl)) {
          _imageCache[dishName] = imgUrl;
          return imgUrl;
        }
      }
    } catch (e) {
      debugPrint("❌ Image API error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>> _callRecipeApi(
    List<Map<String, dynamic>> ingredients,
    Map<String, dynamic> prefs,
  ) async {
    final url =
        Uri.parse("http://3.108.110.151:5001/generate-recipes-ingredient");

    final body = {
      "Meal_Type": [prefs["meal_type"] ?? "lunch"],
      "Serving": int.tryParse(prefs["servings"]?.toString() ?? "1") ?? 1,
      "Ingredients_Available": ingredients,
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to fetch recipes");
    }
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _allRecipes.clear();
    });

    try {
      final json = await _callRecipeApi(
        widget.ingredients,
        widget.preferences,
      );

      final List recipeList =
          json['data']?['Recipes'] ?? [];

      for (var item in recipeList) {
        final recipe = _RecipeData(
          image: "",
          title: item["Dish"] ?? "Unknown Dish",
          cuisine: widget.preferences['cuisine'] ?? "",
          time: "${widget.preferences['time'] ?? 30} min",
        );

        _allRecipes.add(recipe);

        _fetchDishImage(recipe.title).then((img) {
          if (img != null && mounted) {
            recipe.image = img;
            setState(() {});
          }
        });
      }

      setState(() {
        _visibleCount =
            _allRecipes.length >= 3 ? 3 : _allRecipes.length;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
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
                      ingredients: widget.ingredients, // ✅ PASS FROM PARENT
                      preferences: widget.preferences,  // Add this line
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
                              fontSize: 16,
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

  _RecipeData({
    required this.image,
    required this.title,
    required this.cuisine,
    required this.time,
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

