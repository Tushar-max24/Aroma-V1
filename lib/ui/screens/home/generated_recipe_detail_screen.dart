import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/recipe_detail_service.dart';
import '../../../data/services/recipe_generation_service.dart';
import '../recipe_detail/review_section.dart';

class GeneratedRecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const GeneratedRecipeDetailScreen({
    super.key,
    required this.recipeData,
  });

  @override
  State<GeneratedRecipeDetailScreen> createState() => _GeneratedRecipeDetailScreenState();
}

class _GeneratedRecipeDetailScreenState extends State<GeneratedRecipeDetailScreen> {
  bool _isFavorite = false;
  String? _imageUrl;
  bool _imageLoading = false;
  List<Map<String, dynamic>> _reviewData = [];

  @override
  void initState() {
    super.initState();
    print("🔥 DEBUG: GeneratedRecipeDetailScreen initState called");
    print("🔥 DEBUG: Recipe data keys: ${widget.recipeData.keys}");
    print("🔥 DEBUG: Recipe name: ${widget.recipeData['Recipe Name']}");
    
    // Initialize image URL
    _imageUrl = widget.recipeData['image_url'] as String?;
    print("🔥 DEBUG: Initial image_url from recipeData: $_imageUrl");
    
    // Check if image is already generated and valid
    final hasValidImage = _imageUrl != null && 
                        _imageUrl!.isNotEmpty && 
                        !_imageUrl!.contains('pexels.com');
    
    _imageLoading = !hasValidImage;
    
    print("🔥 DEBUG: hasValidImage: $hasValidImage, _imageLoading: $_imageLoading");
    
    // Initialize review data
    final recipeName = widget.recipeData['Recipe Name']?.toString() ?? 'Untitled Recipe';
    _reviewData = _generateSampleReviews(recipeName);
    
    // Start image generation if not available (background, no blocking)
    if (_imageLoading) {
      print("🔥 DEBUG: Starting image generation in detail screen");
      _generateImage();
    }
    
    // Skip MongoDB storage for instant display - store in background if needed
    _storeRecipeToDatabaseInBackground();
  }

  Future<void> _generateImage() async {
    final recipeService = RecipeGenerationService();
    final imageUrl = await recipeService.generateImageForRecipe(widget.recipeData);
    
    if (mounted && imageUrl != null) {
      setState(() {
        _imageUrl = imageUrl;
        _imageLoading = false;
        widget.recipeData['image_url'] = imageUrl;
        widget.recipeData['image_generated'] = true;
      });
    }
  }

  /// Store recipe to MongoDB in background (non-blocking)
  Future<void> _storeRecipeToDatabaseInBackground() async {
    // Don't wait for this - run in background without blocking UI
    Future.microtask(() async {
      try {
        final recipeName = widget.recipeData['Recipe Name']?.toString() ?? 'Untitled Recipe';
        print("📊 DEBUG: Background storing recipe: $recipeName");
        
        // Store without await to avoid blocking
        RecipeDetailService.storeRecipeDetails(recipeName, widget.recipeData).catchError((e) {
          print("⚠️ DEBUG: Background storage failed (non-blocking): $e");
        });
      } catch (e) {
        print("⚠️ DEBUG: Background storage exception (non-blocking): $e");
      }
    });
  }

  /// Generate sample review data based on recipe name
  List<Map<String, dynamic>> _generateSampleReviews(String recipeName) {
    return [
      {
        "name": "Sarah Johnson",
        "rating": 5,
        "comment": "Absolutely loved this $recipeName! The flavors were perfectly balanced and it was so easy to make. Will definitely be making this again.",
        "timeAgo": "2 days ago",
        "isAI": false,
      },
      {
        "name": "Mike Chen",
        "rating": 4,
        "comment": "Great recipe for $recipeName! I added a little extra spice and it turned out amazing. My family loved it.",
        "timeAgo": "1 week ago",
        "isAI": false,
      },
      {
        "name": "Emily Davis",
        "rating": 5,
        "comment": "This $recipeName recipe is now my go-to! Perfect for dinner parties and always gets compliments. Thank you for sharing!",
        "timeAgo": "2 weeks ago",
        "isAI": false,
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    final recipeName = widget.recipeData['Recipe Name']?.toString() ?? 'Untitled Recipe';
    final mealType = widget.recipeData['Meal_Type']?.toString() ?? 'Meal';
    final cookingTime = widget.recipeData['Cooking Time']?.toString() ?? 'N/A';
    final shortDescription = widget.recipeData['Short Description']?.toString() ?? '';
    final ingredientsNeeded = widget.recipeData['Ingredients Needed'] as Map<String, dynamic>? ?? {};
    final preparationSteps = widget.recipeData['Preparation Steps'] as List<dynamic>? ?? [];
    final recipeSteps = widget.recipeData['Recipe Steps'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image with instant display and background loading
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
              ),
              child: Stack(
                children: [
                  // Show image immediately if available, otherwise show placeholder
                  if (_imageUrl != null && _imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: _imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      placeholder: (context, url) => _buildImagePlaceholder(),
                      errorWidget: (context, url, error) => _buildImagePlaceholder(),
                    )
                  else
                    _buildImagePlaceholder(),
                  
                  // Loading indicator on top when image is being generated
                  if (_imageLoading)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Generating image...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Recipe details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe name and meal type
                  Text(
                    recipeName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mealType,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick info row
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        cookingTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  if (shortDescription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      shortDescription,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Ingredients section
                  if (ingredientsNeeded.isNotEmpty) ...[
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...ingredientsNeeded.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  // Preparation steps section
                  if (preparationSteps.isNotEmpty) ...[
                    const Text(
                      'Preparation Steps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...preparationSteps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recipe steps section
                  if (recipeSteps.isNotEmpty) ...[
                    const Text(
                      'Recipe Steps',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...recipeSteps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  // Reviews section
                  const SizedBox(height: 32),
                  ReviewSection(
                    reviews: _reviewData,
                    recipeName: recipeName,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 8),
          Text(
            'Recipe Image',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
