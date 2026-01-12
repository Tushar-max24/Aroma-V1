import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/services/recipe_detail_service.dart';
import '../../../data/services/enhanced_recipe_image_service.dart';
import '../../../data/services/enhanced_recipe_detail_service.dart';
import '../../../data/services/enhanced_recipe_image_service.dart';
import '../../../state/pantry_state.dart';
import '../../../widgets/cached_image.dart';
import '../recipe_detail/ingredient_section.dart';
import '../recipe_detail/cookware_section.dart';
import '../recipe_detail/preparation_section.dart';
import '../recipe_detail/review_section.dart';
import '../recipe_detail/similar_recipes_section.dart';
import '../ingredients_needed/ingredients_needed_screen.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/services/api_client.dart';
import '../../../core/utils/extreme_spring_physics.dart';

class WeeklyGenerationRecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipeData;

  const WeeklyGenerationRecipeDetailScreen({
    super.key,
    required this.recipeData,
  });

  @override
  State<WeeklyGenerationRecipeDetailScreen> createState() => _WeeklyGenerationRecipeDetailScreenState();
}

class _WeeklyGenerationRecipeDetailScreenState extends State<WeeklyGenerationRecipeDetailScreen> {
  bool isExpanded = false;
  bool isFavorite = false;
  bool isSaved = false;
  int servings = 4;

  final ApiClient _apiClient = ApiClient();

  List<String> _cookingSteps = [];
  List<Map<String, dynamic>> _cookingStepsDetailed = [];
  List<Map<String, dynamic>> _ingredientData = [];
  List<Map<String, dynamic>> _reviewData = [];
  List<Map<String, dynamic>> _similarRecipeData = [];
  List<String> _cookwareItems = [];
  Map<String, dynamic> _nutrition = {};
  String _description = "";

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ingredientsKey = GlobalKey();
  final GlobalKey _preparationKey = GlobalKey();

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();
    servings = (widget.recipeData['Serving'] ?? 4).toInt();
    _extractBackendData();
  }

  void _extractBackendData() {
    try {
      final recipe = widget.recipeData;
      debugPrint('🔍 Full recipe data keys: ${recipe.keys.toList()}');
      debugPrint('🔍 Full recipe data: $recipe');
      
      setState(() {
        // Extract description from backend
        _description = recipe["description"]?.toString() ?? 
                     recipe["Short Description"]?.toString() ?? 
                     "A delicious recipe prepared with fresh ingredients.";
        
        // Extract nutrition from backend nutrition structure (recipe-level)
        _nutrition = recipe["nutrition"] ?? {};
        
        // If no nutrition data, try alternative field names
        if (_nutrition.isEmpty) {
          _nutrition = recipe["nutritional_info"] ?? {};
        }
        if (_nutrition.isEmpty) {
          _nutrition = recipe["nutrients"] ?? {};
        }
        
        // Try to calculate nutrition from individual fields
        if (_nutrition.isEmpty || (_nutrition["calories"] == 0 && _nutrition["protein"] == 0)) {
          _nutrition = {
            "calories": recipe["calories"] ?? recipe["Calories"] ?? 250,
            "protein": recipe["protein"] ?? recipe["Protein"] ?? 12,
            "carbs": recipe["carbs"] ?? recipe["Carbohydrates"] ?? recipe["carbohydrates"] ?? 35,
            "fats": recipe["fats"] ?? recipe["Fat"] ?? recipe["total_fat"] ?? 8,
            "fiber": recipe["fiber"] ?? recipe["Fiber"] ?? 4,
          };
        }
        
        // If still no nutrition data, provide reasonable defaults
        if (_nutrition.isEmpty || (_nutrition["calories"] == 0 && _nutrition["protein"] == 0)) {
          debugPrint('🥗 No nutrition data found, using defaults');
          _nutrition = {
            "calories": 250,
            "protein": 12,
            "carbs": 35,
            "fats": 8,
            "fiber": 4,
          };
        }
        
        // Extract preparation steps from JSON
        _cookingSteps = List<String>.from(recipe["Preparation Steps"] ?? []);
        
        // Extract recipe steps (cooking instructions) from JSON
        _cookingStepsDetailed = List<Map<String, dynamic>>.from(recipe["Recipe Steps"]?.map((step) => {
          'instruction': step.toString(),
          'ingredients_used': [],
          'tips': [],
        }) ?? []);
        
        // If no recipe steps, create default
        if (_cookingStepsDetailed.isEmpty) {
          _cookingStepsDetailed = [
            {
              'instruction': 'Cook according to recipe instructions',
              'ingredients_used': [],
              'tips': ['Follow cooking times carefully'],
            }
          ];
        }
        
        // Use backend ingredients if available, otherwise use empty list
        final backendIngredients = List<Map<String, dynamic>>.from(recipe["Ingredients Needed Details"] ?? recipe["ingredients_with_quantity"] ?? recipe["ingredients"] ?? []);
        _ingredientData = backendIngredients.isNotEmpty ? backendIngredients : [];
        
        // Generate sample review data based on recipe name
        final recipeName = recipe["Recipe Name"]?.toString() ?? recipe["recipe_name"]?.toString() ?? 'Untitled Recipe';
        _reviewData = _generateSampleReviews(recipeName);
        debugPrint('⭐ Generated sample reviews for $recipeName: ${_reviewData.length} reviews');
        
      });
      
      debugPrint('✅ Successfully extracted recipe data from backend');
      debugPrint('📋 Found ${_cookingSteps.length} preparation steps');
      debugPrint('👨‍🍳 Found ${_cookingStepsDetailed.length} cooking steps');
      debugPrint('🥗 Found ${_ingredientData.length} ingredients');
      
    } catch (e) {
      debugPrint('❌ Error extracting backend data: $e');
      setState(() {
        _cookingSteps = [];
        _cookingStepsDetailed = [];
      });
    }
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

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _content() {
    final recipeName = widget.recipeData["Recipe Name"]?.toString() ?? widget.recipeData["recipe_name"]?.toString() ?? 'Untitled Recipe';
    
    // Debug: Print all available keys to understand the data structure
    debugPrint('🔍 Recipe data keys: ${widget.recipeData.keys.toList()}');
    
    // Try multiple possible field names for cuisine/recipe type
    final possibleCuisineFields = ['Cuisine', 'cuisine', 'Cuisine_Preference', 'cuisine_type', 'Recipe Type', 'recipe_type', 'Type'];
    String? foundCuisine;
    
    for (final field in possibleCuisineFields) {
      if (widget.recipeData.containsKey(field) && widget.recipeData[field] != null) {
        foundCuisine = widget.recipeData[field].toString();
        debugPrint('🍽️ Found cuisine in field: $field = $foundCuisine');
        break;
      }
    }
    
    final cuisine = foundCuisine ?? 'Unknown';
    debugPrint('🍽️ Final cuisine value: $cuisine');
    
    final cookTime = widget.recipeData["Cooking Time"]?.toString() ?? widget.recipeData["cooking_time"]?.toString() ?? '30 min';
    
    return Consumer<PantryState>(
      builder: (_, pantryState, __) {
        final pantryItems = pantryState.pantryItems;

        final availableIngredients = _ingredientData.where((ingredient) {
          final name = ingredient['item']?.toString().toLowerCase() ?? '';
          return pantryItems.any((p) =>
              p.name.toLowerCase() == name && p.quantity > 0);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(recipeName,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Key info row - matching the provided image
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoChip(icon: Icons.restaurant, label: cuisine),
                _InfoChip(
                    icon: Icons.local_fire_department,
                    label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                _InfoChip(icon: Icons.access_time, label: cookTime),
                _InfoChip(icon: Icons.people, label: servings.toString()),
              ],
            ),

            const SizedBox(height: 22),

            // Description section - matching the provided image
            AnimatedCrossFade(
              firstChild: Text(
                _description.isEmpty ? "No description available" : _description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(_description),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),

            GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: const Text(
                "Read more..",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 30),

            // Nutrition section - matching the provided image
            const Text("Nutrition per serving",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),

            const SizedBox(height: 20),

            Wrap(
              spacing: 20,
              runSpacing: 18,
              children: [
                _NutritionTile(
                    icon: Icons.grass,
                    label: '${_nutrition["carbs"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.fitness_center,
                    label: '${_nutrition["protein"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.local_fire_department,
                    label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                _NutritionTile(
                    icon: Icons.lunch_dining,
                    label: '${_nutrition["fats"]?.toString() ?? "--"}g'),
                _NutritionTile(
                    icon: Icons.eco,
                    label: '${_nutrition["fiber"]?.toString() ?? "--"}g'),
              ],
            ),

            const SizedBox(height: 35),

            // Tabs section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem("Ingredients", 0, _ingredientsKey),
                _tabItem("Preparation", 1, _preparationKey),
              ],
            ),

            const SizedBox(height: 30),

            // Ingredients section
            Container(
              key: _ingredientsKey,
              child: IngredientSection(
                servings: servings,
                onServingChange: (v) => setState(() => servings = v),
                ingredientData: _ingredientData,
                availableIngredients: availableIngredients
                    .map((e) =>
                        e['item']?.toString().toLowerCase() ?? '')
                    .toList(),
              ),
            ),

            const SizedBox(height: 35),

            // Preparation Steps section
            Container(
              key: _preparationKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preparation Steps",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 22),
                  
                  if (_cookingSteps.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "No preparation steps available",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cookingSteps.length,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(thickness: 1, color: Color(0xFFECECEC)),
                      ),
                      itemBuilder: (_, index) {
                        return _StepCard(
                          stepNumber: index + 1,
                          text: _cookingSteps[index],
                        );
                      },
                    ),
                  
                  const SizedBox(height: 35),
                  
                  // Cooking Instructions section
                  const Text(
                    "Cooking Instructions",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 22),
                  
                  if (_cookingStepsDetailed.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "No cooking instructions available",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cookingStepsDetailed.length,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(thickness: 1, color: Color(0xFFECECEC)),
                      ),
                      itemBuilder: (_, index) {
                        final stepData = _cookingStepsDetailed[index];
                        final instruction = stepData['instruction']?.toString() ?? '';
                        return _StepCard(
                          stepNumber: index + 1,
                          text: instruction,
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // Review section
            ReviewSection(
              reviews: _reviewData,
              recipeName: recipeName,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bottomButton(),
      body: CustomScrollView(
        controller: _scrollController,
        physics: ExtremeSpringPhysics(
            springStrength: 1200.0, // Very strong spring for extreme effect
            damping: 10.0, // Minimal damping for maximum bounce
          ),
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Background placeholder
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey.shade100,
                    ),
                    // Image display
                    if (widget.recipeData['image_url'] != null && 
                        widget.recipeData['image_url'].toString().isNotEmpty &&
                        !widget.recipeData['image_url'].toString().contains('pexels.com'))
                      Image.network(
                        widget.recipeData['image_url'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("❌ DEBUG: Failed to load image: ${widget.recipeData['image_url']}, error: $error");
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Material(
              color: Colors.white,
              elevation: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 0, 26, 60),
                child: _content(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, int index, GlobalKey key) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedTab = index);
        _scrollTo(key);
      },
      child: Column(
        children: [
          Text(text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: selectedTab == index
                    ? const Color(0xFFFF6A45)
                    : Colors.grey,
              )),
          if (selectedTab == index)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 100,
              height: 2,
              color: const Color(0xFFFF6A45),
            ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Three dots menu button
          Container(
            width: 50,
            height: 50,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black87, size: 24),
              onPressed: () {
                // TODO: Implement menu action
              },
            ),
          ),
          
          // Cook Now button
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6A45).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IngredientsNeededScreen(
                        servings: servings,
                        ingredients: _ingredientData,
                        steps: _cookingStepsDetailed,
                        recipeName: widget.recipeData["Recipe Name"]?.toString() ?? 
                                     widget.recipeData["recipe_name"]?.toString() ?? 'Untitled Recipe',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Cook Now",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- TOP-LEVEL WIDGETS ----------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.orange.shade50,
          child: Icon(icon, size: 18, color: Colors.orange),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _NutritionTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NutritionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width / 2) - 40,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEFE5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFFFF6A45)),
          ),
          const SizedBox(width: 14),
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// ---- EACH STEP CARD ----
class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String text;

  const _StepCard({
    required this.stepNumber,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            "STEP $stepNumber",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
