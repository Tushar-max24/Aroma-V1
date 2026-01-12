import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/extreme_spring_physics.dart';
import 'ingredient_section.dart';
import 'cookware_section.dart';
import 'preparation_section.dart';
import 'review_section.dart';
import 'similar_recipes_section.dart';
import '../ingredients_needed/ingredients_needed_screen.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/recipe_detail_service.dart';
import '../../../data/services/enhanced_recipe_detail_service.dart';
import '../../../data/services/enhanced_recipe_image_service.dart';
import '../../../state/pantry_state.dart';
import 'package:provider/provider.dart';
import '../../../widgets/cached_image.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String image;
  final String title;
  final List<Map<String, dynamic>> ingredients;
  final String cuisine;
  final String cookTime;
  final int servings;
  final Map<String, dynamic> fullRecipeData; // Complete backend data

  const RecipeDetailScreen({
    super.key,
    required this.image,
    required this.title,
    required this.ingredients,
    required this.cuisine,
    required this.cookTime,
    required this.servings,
    required this.fullRecipeData,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> with TickerProviderStateMixin {
  bool isExpanded = false;
  bool isFavorite = false;
  bool isSaved = false;
  int servings = 4;

  final ApiClient _apiClient = ApiClient();

  List<String> _cookingSteps = [];
  List<Map<String, dynamic>> _cookingStepsDetailed = [];
  List<Map<String, dynamic>> _ingredientData = [];
  List<Map<String, String>> _reviewData = [];
  List<Map<String, dynamic>> _similarRecipeData = [];
  List<String> _cookwareItems = [];
  Map<String, dynamic> _nutrition = {}; // Store nutrition data
  String _description = ""; // Store description from backend

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ingredientsKey = GlobalKey();
  final GlobalKey _cookwareKey = GlobalKey();
  final GlobalKey _preparationKey = GlobalKey();

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    try {
      servings = widget.servings;
      _ingredientData = widget.ingredients;
      
      // Add debug to see what data we're receiving
      debugPrint('🔍 RecipeDetailScreen initState called');
      debugPrint('🔍 widget.fullRecipeData keys: ${widget.fullRecipeData.keys.toList()}');
      debugPrint('🔍 widget.fullRecipeData: ${widget.fullRecipeData}');
      
      // Start data extraction in background to avoid blocking navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Store recipe to MongoDB when screen opens
        _storeRecipeToMongoDB();
        
        // Cache ingredient images in MongoDB using enhanced service
        _cacheIngredientImages();
        
        // Cache recipe image in MongoDB using enhanced service
        _cacheRecipeImage();
        
        // Extract backend data
        _extractBackendData();
      });
    } catch (e) {
      debugPrint('❌ RecipeDetailScreen initState error: $e');
    }
  }

  /// Store the current recipe to MongoDB
  Future<void> _storeRecipeToMongoDB() async {
    try {
      print("🔥🔥🔥 REAL DEBUG: Storing recipe to MongoDB: ${widget.title}");
      print("🔥🔥🔥 REAL DEBUG: Recipe data keys: ${widget.fullRecipeData.keys}");
      
      // Store the complete recipe data using RecipeDetailService
      await RecipeDetailService.storeRecipeDetails(widget.title, widget.fullRecipeData);
      print("🔥🔥🔥 REAL DEBUG: Recipe storage completed");
    } catch (e) {
      print("❌ REAL DEBUG: Error storing recipe to MongoDB: $e");
      print("❌ REAL DEBUG: Stack trace: ${StackTrace.current}");
    }
  }

  /// Cache ingredient images from recipe data using enhanced MongoDB-first workflow
  Future<void> _cacheIngredientImages() async {
    try {
      debugPrint('🔄 [Recipe Detail] Starting ingredient image caching for: ${widget.title}');
      
      // Use enhanced recipe detail service to process and cache ingredient images
      await EnhancedRecipeDetailService.fetchRecipeDetailsWithIngredientCaching(widget.title);
      
      debugPrint('✅ [Recipe Detail] Ingredient image caching completed for: ${widget.title}');
    } catch (e) {
      debugPrint('❌ [Recipe Detail] Error caching ingredient images: $e');
    }
  }

  /// Cache recipe image from recipe data using enhanced MongoDB-first workflow
  Future<void> _cacheRecipeImage() async {
    try {
      debugPrint('🔄 [Recipe Detail] Starting recipe image caching for: ${widget.title}');
      
      // Use enhanced recipe image service to cache the recipe image
      await EnhancedRecipeImageService.getRecipeImage(widget.title, imageUrl: widget.image);
      
      debugPrint('✅ [Recipe Detail] Recipe image caching completed for: ${widget.title}');
    } catch (e) {
      debugPrint('❌ [Recipe Detail] Error caching recipe image: $e');
    }
  }

  void _extractBackendData() async {
    try {
      debugPrint('🔍 [RecipeDetailScreen] Using unified API for: ${widget.title}');
      
      // Use the new simplified API to get recipe details
      final recipeData = await RecipeDetailService.fetchRecipeDetails(widget.title);
      
      debugPrint('✅ [RecipeDetailScreen] Got recipe data from unified API');
      debugPrint('🔍 Recipe data keys: ${recipeData.keys.toList()}');
      
      setState(() {
        // Extract description from backend
        _description = recipeData["Description"]?.toString() ?? recipeData["description"]?.toString() ?? "";
        
        // Extract nutrition from backend nutrition structure (recipe-level)
        _nutrition = recipeData["Nutrition"] ?? recipeData["nutrition"] ?? {};
        
        // If no nutrition data, try alternative field names
        if (_nutrition.isEmpty) {
          _nutrition = recipeData["nutritional_info"] ?? {};
        }
        if (_nutrition.isEmpty) {
          _nutrition = recipeData["nutrients"] ?? {};
        }
        
        // Try to extract from individual fields
        if (_nutrition.isEmpty) {
          _nutrition = {
            "calories": recipeData["calories"] ?? recipeData["Calories"] ?? 0,
            "protein": recipeData["protein"] ?? recipeData["Protein"] ?? 0,
            "carbs": recipeData["carbs"] ?? recipeData["Carbohydrates"] ?? recipeData["carbohydrates"] ?? 0,
            "fats": recipeData["fats"] ?? recipeData["Fat"] ?? recipeData["total_fat"] ?? 0,
            "fiber": recipeData["fiber"] ?? recipeData["Fiber"] ?? 0,
          };
        }
        
        // Extract other data from unified API response
        _cookingSteps = (recipeData["Preparation Steps"] ?? recipeData["preparation_steps"] ?? recipeData["Recipe Steps"] ?? recipeData["recipe_steps"] ?? []).cast<String>();
        
        _cookwareItems = (recipeData["Cookware"] ?? recipeData["cookware"] ?? []).cast<String>();
        
        // Extract reviews if available (simplified to avoid casting errors)
        _reviewData = []; // Initialize empty for now to avoid casting issues
        
        // Extract similar recipes if available
        _similarRecipeData = (recipeData["Similar Recipes"] ?? recipeData["similar_recipes"] ?? []).cast<Map<String, dynamic>>();
        
        debugPrint('✅ [RecipeDetailScreen] Data extraction completed from unified API');
      });
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error extracting data from unified API: $e');
    }
  }

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            widget.title ?? 'Recipe',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoChip(icon: Icons.restaurant, label: widget.cuisine ?? 'Unknown'),
              _InfoChip(
                  icon: Icons.local_fire_department,
                  label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
              _InfoChip(icon: Icons.access_time, label: widget.cookTime ?? 'N/A'),
              _InfoChip(icon: Icons.people, label: servings.toString()),
            ],
          ),

          const SizedBox(height: 22),

          // Description
          Text(
            _description.isEmpty ? "No description available" : _description,
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 30),

          // Nutrition chips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition per serving',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NutritionChip('Carbs', '${_nutrition["carbs"]?.toString() ?? "--"}g'),
                    _NutritionChip('Protein', '${_nutrition["protein"]?.toString() ?? "--"}g'),
                    _NutritionChip('Calories', '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                    _NutritionChip('Fats', '${_nutrition["fats"]?.toString() ?? "--"}g'),
                    _NutritionChip('Fiber', '${_nutrition["fiber"]?.toString() ?? "--"}g'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Tab navigation
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _tabItem("Ingredients", 0, _ingredientsKey),
                _tabItem("Cookware", 1, _cookwareKey),
                _tabItem("Preparation", 2, _preparationKey),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab content
          SizedBox(
            height: 400, // Fixed height to prevent unbounded constraints
            child: TabBarView(
              controller: TabController(length: 3, vsync: this),
              children: [
                // Ingredients tab
                _buildIngredientsTab(),
                // Cookware tab
                _buildCookwareTab(),
                // Preparation tab
                _buildPreparationTab(),
              ],
            ),
          ),

          // Similar recipes section
          if (_similarRecipeData != null && _similarRecipeData.isNotEmpty)
            SimilarRecipesSection(recipes: _similarRecipeData),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    try {
      return IngredientSection(
        key: _ingredientsKey,
        ingredientData: _ingredientData ?? [],
        servings: servings,
        onServingChange: (v) => setState(() => servings = v),
      );
    } catch (e) {
      debugPrint('❌ Error building ingredients tab: $e');
      return Container(
        height: 400,
        child: const Center(child: Text('Unable to load ingredients')),
      );
    }
  }

  Widget _buildCookwareTab() {
    try {
      return CookwareSection(
        key: _cookwareKey,
        cookwareItems: _cookwareItems ?? [],
        servings: servings,
      );
    } catch (e) {
      debugPrint('❌ Error building cookware tab: $e');
      return Container(
        height: 400,
        child: const Center(child: Text('Unable to load cookware')),
      );
    }
  }

  Widget _buildPreparationTab() {
    try {
      return PreparationSection(
        key: _preparationKey,
        steps: _cookingSteps ?? [],
      );
    } catch (e) {
      debugPrint('❌ Error building preparation tab: $e');
      return Container(
        height: 400,
        child: const Center(child: Text('Unable to load preparation steps')),
      );
    }
  }

  Widget _tabItem(String title, int index, GlobalKey key) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _scrollTo(key);
          setState(() => selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selectedTab == index
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selectedTab == index ? Colors.white : Colors.black54,
              fontWeight: selectedTab == index
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header with image
            Container(
              height: 300,
              width: double.infinity,
              child: FutureBuilder<String?>(
                future: EnhancedRecipeImageService.getRecipeImage(widget.title, imageUrl: widget.image),
                builder: (context, snapshot) {
                  final imageUrl = snapshot.data;
                  return CachedImage(
                    imageUrl: imageUrl ?? widget.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            
            // Content
            _content(),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
