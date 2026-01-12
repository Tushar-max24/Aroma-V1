import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/recipe_generation_service.dart';
import '../recipe_detail/recipe_detail_screen.dart';
import '../home/generated_recipe_detail_screen.dart';
import '../../widgets/recipe_card.dart';

class GeneratedRecipeListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> ingredients;
  final Map<String, dynamic> preferences;

  const GeneratedRecipeListScreen({
    super.key,
    required this.ingredients,
    required this.preferences,
  });

  @override
  State<GeneratedRecipeListScreen> createState() => _GeneratedRecipeListScreenState();
}

class _GeneratedRecipeListScreenState extends State<GeneratedRecipeListScreen> {
  final RecipeGenerationService _recipeService = RecipeGenerationService();
  List<Map<String, dynamic>> _recipes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateRecipes();
  }

  Future<void> _generateRecipes() async {
    debugPrint("🚀 [RecipeListScreen] Starting recipe generation at: ${DateTime.now().millisecondsSinceEpoch}");
    
    try {
      // Combine ingredients and preferences for the API
      final requestData = {
        ...widget.preferences,
        'Ingredients_Available': widget.ingredients.map((ing) => ing['item'] ?? ing.toString()).toList(),
      };

      debugPrint("📡 [RecipeListScreen] Sending recipe generation request");
      
      // Generate recipes instantly - no cache checking
      final recipes = await _recipeService.generateRecipes(requestData);
      
      debugPrint("✅ [RecipeListScreen] Generated ${recipes.length} recipes instantly");
      
      setState(() {
        _recipes = recipes;
        _isLoading = false;
      });
      
      debugPrint("🎯 [RecipeListScreen] UI updated instantly, images loading in background");
    } catch (e) {
      debugPrint("❌ [RecipeListScreen] Error: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _refreshRecipes() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _generateRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Generated Recipes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: _refreshRecipes,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Generating recipes...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to generate recipes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshRecipes,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_recipes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No recipes found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Try adjusting your preferences',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _generateRecipes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return _RecipeCard(
            recipe: recipe,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GeneratedRecipeDetailScreen(
                    recipeData: recipe,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RecipeCard extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.onTap,
  });

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard> {
  bool _imageLoading = true;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.recipe['image_url'] as String?;
    _imageLoading = _imageUrl == null || _imageUrl!.isEmpty;
    
    // Start image generation if not available
    if (_imageLoading) {
      _generateImage();
    }
  }

  Future<void> _generateImage() async {
    final recipeService = RecipeGenerationService();
    final imageUrl = await recipeService.generateImageForRecipe(widget.recipe);
    
    if (mounted && imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
        _imageLoading = false;
        widget.recipe['image_url'] = imageUrl;
        widget.recipe['image_generated'] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image with placeholder
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[200],
                child: _buildImage(),
              ),
            ),
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe['Recipe Name'] ?? 'Unknown Recipe',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.recipe['Description'] ?? 'No description available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.recipe['Cooking_Time'] != null) ...[
                        const Icon(Icons.schedule, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          widget.recipe['Cooking_Time'],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (widget.recipe['Serving'] != null) ...[
                        const Icon(Icons.people, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.recipe['Serving']} servings',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
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

  Widget _buildImage() {
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          if (_imageLoading)
            const CircularProgressIndicator()
          else
            Text(
              'No Image',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
