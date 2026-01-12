import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/services/recipe_detail_service.dart';
import '../../../data/services/recipe_generation_service.dart';

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

  @override
  void initState() {
    super.initState();
    print("🔥 DEBUG: GeneratedRecipeDetailScreen initState called");
    print("🔥 DEBUG: Recipe data keys: ${widget.recipeData.keys}");
    print("🔥 DEBUG: Recipe name: ${widget.recipeData['Recipe Name']}");
    
    // Initialize image URL
    _imageUrl = widget.recipeData['image_url'] as String?;
    _imageLoading = _imageUrl == null || _imageUrl!.isEmpty;
    
    // Start image generation if not available
    if (_imageLoading) {
      _generateImage();
    }
    
    // Store recipe details to MongoDB when screen opens
    _storeRecipeToDatabase();
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

  /// Store the current recipe to MongoDB
  Future<void> _storeRecipeToDatabase() async {
    try {
      final recipeName = widget.recipeData['Recipe Name']?.toString() ?? 'Untitled Recipe';
      print("📊 DEBUG: About to store recipe to MongoDB: $recipeName");
      print("📊 DEBUG: Recipe data type: ${widget.recipeData.runtimeType}");
      
      // Store the complete recipe data using RecipeDetailService
      print("📊 DEBUG: Calling RecipeDetailService.storeRecipeDetails...");
      await RecipeDetailService.storeRecipeDetails(recipeName, widget.recipeData);
      print("📊 DEBUG: RecipeDetailService.storeRecipeDetails completed");
    } catch (e) {
      print("❌ DEBUG: Error storing recipe to database: $e");
      print("❌ DEBUG: Stack trace: ${StackTrace.current}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeName = widget.recipeData['Recipe Name']?.toString() ?? 'Untitled Recipe';
    final mealType = widget.recipeData['Meal_Type']?.toString() ?? 'Meal';
    final cookingTime = widget.recipeData['Cooking Time']?.toString() ?? 'N/A';
    final shortDescription = widget.recipeData['Short Description']?.toString() ?? '';
    final imageUrl = widget.recipeData['Image']?['image_url']?.toString();
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
                  
                  if (shortDescription.isNotEmpty) ..[
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
                  if (ingredientsNeeded.isNotEmpty) ..[
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
                  if (preparationSteps.isNotEmpty) ..[
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
                  if (recipeSteps.isNotEmpty) ..[
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
                  // Preparation Steps Section
                  if (preparationSteps.isNotEmpty) ...[
                    _buildSectionTitle('Preparation Steps'),
                    const SizedBox(height: 12),
                    _buildStepsCard(preparationSteps, isPreparation: true),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recipe Steps Section
                  if (recipeSteps.isNotEmpty) ...[
                    _buildSectionTitle('Recipe Steps'),
                    const SizedBox(height: 12),
                    _buildStepsCard(recipeSteps, isPreparation: false),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildIngredientsCard(Map<String, dynamic> ingredients) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...ingredients.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7A4A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        if (entry.value.toString().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (ingredients.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No ingredients listed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsCard(List<dynamic> steps, {required bool isPreparation}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPreparation ? const Color(0xFFFF7A4A).withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isPreparation 
              ? const Color(0xFFFF7A4A).withOpacity(0.2)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value.toString();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number
                  Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isPreparation 
                          ? const Color(0xFFFF7A4A)
                          : const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  // Step text
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (steps.isEmpty) ...[
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No steps listed',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
