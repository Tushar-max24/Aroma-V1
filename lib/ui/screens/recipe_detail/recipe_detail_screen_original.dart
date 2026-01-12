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

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
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
    servings = widget.servings;
    _ingredientData = widget.ingredients;
    
    // Add debug to see what data we're receiving
    debugPrint('🔍 RecipeDetailScreen initState called');
    debugPrint('🔍 widget.fullRecipeData keys: ${widget.fullRecipeData.keys.toList()}');
    debugPrint('🔍 widget.fullRecipeData: ${widget.fullRecipeData}');
    
    // Store recipe to MongoDB when screen opens
    _storeRecipeToMongoDB();
    
    // Cache ingredient images in MongoDB using enhanced service
    _cacheIngredientImages();
    
    // Cache recipe image in MongoDB using enhanced service
    _cacheRecipeImage();
    
    _extractBackendData();
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
        _cookingSteps = (recipeData["Preparation Steps"] ?? recipeData["preparation_steps"] ?? recipeData["Recipe Steps"] ?? recipeData["recipe_steps"] ?? []) as List<dynamic>;
        
        _cookwareItems = (recipeData["Cookware"] ?? recipeData["cookware"] ?? []) as List<dynamic>;
        
        // Extract reviews if available
        _reviewData = (recipeData["Reviews"] ?? recipeData["reviews"] ?? []) as List<Map<String, dynamic>>;
        
        // Extract similar recipes if available
        _similarRecipeData = (recipeData["Similar Recipes"] ?? recipeData["similar_recipes"] ?? []) as List<Map<String, dynamic>>;
        
        debugPrint('✅ [RecipeDetailScreen] Data extraction completed from unified API');
      });
    } catch (e) {
      debugPrint('❌ [RecipeDetailScreen] Error extracting data from unified API: $e');
    }
  }  
          if (totalCalories > 0 || totalProtein > 0) {
            _nutrition = {
              "calories": totalCalories.round(),
              "protein": totalProtein.toStringAsFixed(1),
              "carbs": totalCarbs.toStringAsFixed(1),
              "fats": totalFats.toStringAsFixed(1),
              "fiber": totalFiber.toStringAsFixed(1),
            };
            debugPrint('🥗 Calculated nutrition from ingredients: $_nutrition');
          }
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
        
        debugPrint('🔍 Recipe-level nutrition: ${_nutrition}');
        debugPrint('🔍 Calories: ${_nutrition["calories"]}');
        debugPrint('🔍 Protein: ${_nutrition["protein"]}');
        debugPrint('🔍 Carbs: ${_nutrition["carbs"]}');
        debugPrint('🔍 Fats: ${_nutrition["fats"]}');
        
        // Extract cooking steps from backend
        _cookingStepsDetailed = List<Map<String, dynamic>>.from(recipeData["cooking_steps"] ?? []);
        
        debugPrint('🔍 RAW COOKING STEPS FROM API:');
        debugPrint('🔍 Number of steps: ${_cookingStepsDetailed.length}');
        for (int i = 0; i < _cookingStepsDetailed.length; i++) {
          final step = _cookingStepsDetailed[i];
          debugPrint('🔍 Step ${i + 1}:');
          debugPrint('   - Keys: ${step.keys.toList()}');
          debugPrint('   - Instruction: ${step['instruction']}');
          debugPrint('   - ingredients_used: ${step['ingredients_used']}');
          debugPrint('   - ingredients_used type: ${step['ingredients_used']?.runtimeType}');
          if (step['ingredients_used'] != null && step['ingredients_used'] is List) {
            debugPrint('   - ingredients_used length: ${(step['ingredients_used'] as List).length}');
          }
        }
        
        // If no cooking steps, create default steps with ingredients
        if (_cookingStepsDetailed.isEmpty) {
          final allIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
          _cookingStepsDetailed = [
            {
              'instruction': 'Prepare all ingredients',
              'ingredients_used': allIngredients,
              'tips': ['Wash and clean all ingredients before use'],
            },
            {
              'instruction': 'Cook according to recipe instructions',
              'ingredients_used': allIngredients,
              'tips': ['Follow cooking times carefully'],
            }
          ];
        } else {
          // Process existing cooking steps and intelligently distribute ingredients across steps
          final allIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
          
          debugPrint('🔍 Processing ${_cookingStepsDetailed.length} cooking steps');
          debugPrint('🔍 Available ingredients: ${allIngredients.length}');
          
          _cookingStepsDetailed = _cookingStepsDetailed.asMap().entries.map((entry) {
            final stepIndex = entry.key;
            final step = entry.value;
            final instruction = (step['instruction'] ?? '').toString().toLowerCase();
            
            debugPrint('🔍 Step ${stepIndex + 1} data: ${step.keys.toList()}');
            debugPrint('🔍 Step ${stepIndex + 1} instruction: "$instruction"');
            debugPrint('🔍 Step ${stepIndex + 1} ingredients_used: ${step['ingredients_used']}');
            
            // Only assign ingredients if step completely lacks ingredient data
            if (!step.containsKey('ingredients_used')) {
              debugPrint('⚠️ Step ${stepIndex + 1} has no ingredients_used field - distributing ingredients');
              
              // Smart ingredient distribution across steps
              List<Map<String, dynamic>> stepIngredients = [];
              
              // Look for ingredients mentioned in the instruction
              for (var ingredient in allIngredients) {
                final ingredientName = (ingredient['item'] ?? ingredient['name'] ?? '').toString().toLowerCase();
                if (instruction.contains(ingredientName) || 
                    instruction.contains(ingredientName.replaceAll(' ', '')) ||
                    instruction.contains(ingredientName.split(' ')[0])) {
                  stepIngredients.add(ingredient);
                  debugPrint('   - Found relevant ingredient: $ingredientName');
                }
              }
              
              // If no ingredients found in instruction, distribute ingredients evenly across steps
              if (stepIngredients.isEmpty) {
                final totalSteps = _cookingStepsDetailed.length;
                final ingredientsPerStep = (allIngredients.length / totalSteps).ceil();
                final startIndex = stepIndex * ingredientsPerStep;
                final endIndex = (startIndex + ingredientsPerStep).clamp(0, allIngredients.length);
                
                if (startIndex < allIngredients.length) {
                  stepIngredients = allIngredients.sublist(startIndex, endIndex);
                  debugPrint('   - Distributing ingredients $startIndex to $endIndex: ${stepIngredients.map((i) => i['item']).toList()}');
                }
              }
              
              // Ensure at least 1 ingredient per step
              if (stepIngredients.isEmpty && allIngredients.isNotEmpty) {
                stepIngredients = [allIngredients[stepIndex % allIngredients.length]];
                debugPrint('   - Assigned fallback ingredient: ${stepIngredients.first['item']}');
              }
              
              step['ingredients_used'] = stepIngredients;
              debugPrint('   - Assigned ${stepIngredients.length} ingredients to step ${stepIndex + 1}');
            } else {
              debugPrint('✅ Step ${stepIndex + 1} has its own ingredients_used data');
            }
            
            return step;
          }).toList();
        }
        
        // Extract cooking steps text for preview
        _cookingSteps = _cookingStepsDetailed
            .map((e) => (e['instruction'] ?? '').toString())
            .where((s) => s.trim().isNotEmpty)
            .toList();
        
        // Extract cookware from tags
        final tags = recipeData["tags"] ?? {};
        debugPrint('🔍 Raw recipeData: $recipeData');
        debugPrint('🔍 recipeData keys: ${recipeData.keys.toList()}');
        debugPrint('🔍 recipeData type: ${recipeData.runtimeType}');
        debugPrint('🔍 Raw tags data: $tags');
        debugPrint('🔍 Raw tags data: $tags');
        debugPrint('🔍 Tags keys: ${tags.keys.toList()}');
        debugPrint('🔍 Tags type: ${tags.runtimeType}');
        debugPrint('🔍 Cookware from tags: ${tags["cookware"]}');
        debugPrint('🔍 Cookware from tags type: ${tags["cookware"].runtimeType}');
        _cookwareItems = List<String>.from(tags["cookware"] ?? []);
        debugPrint('🔪 Final cookware items: $_cookwareItems');
        debugPrint('🔪 Cookware items length: ${_cookwareItems.length}');
        
        // TEMP TEST: Add test cookware if empty to verify display works
        if (_cookwareItems.isEmpty) {
          debugPrint('🔪 Adding test cookware items');
          _cookwareItems = ['Gas Stove', 'Pan', 'Blender'];
          debugPrint('🔪 Test cookware items: $_cookwareItems');
        }
        
        // Use backend ingredients if available, otherwise use widget ingredients
        final backendIngredients = List<Map<String, dynamic>>.from(recipeData["ingredients_with_quantity"] ?? recipeData["ingredients"] ?? []);
        _ingredientData = backendIngredients.isNotEmpty ? backendIngredients : widget.ingredients;
        
        debugPrint('🔍 Backend ingredients: ${recipeData["ingredients"]}');
        debugPrint('🔍 Widget ingredients: ${widget.ingredients}');
        debugPrint('🔍 Final _ingredientData: $_ingredientData');
        
      });
      
      debugPrint('✅ Successfully extracted recipe data from backend');
      debugPrint('📋 Found ${_cookingSteps.length} cooking steps');
      debugPrint('🔪 Found ${_cookwareItems.length} cookware items');
      debugPrint('🥗 Found ${_ingredientData.length} ingredients');
      
    } catch (e) {
      debugPrint('❌ Error extracting backend data: $e');
      setState(() {
        _cookingSteps = [];
        _cookingStepsDetailed = [];
      });
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
            Text(widget.title,
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoChip(icon: Icons.restaurant, label: widget.cuisine),
                _InfoChip(
                    icon: Icons.local_fire_department,
                    label: '${_nutrition["calories"]?.toString() ?? "--"} cal'),
                _InfoChip(icon: Icons.access_time, label: widget.cookTime),
                _InfoChip(icon: Icons.people, label: servings.toString()),
              ],
            ),

            const SizedBox(height: 22),

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem("Ingredients", 0, _ingredientsKey),
                _tabItem("Cookware", 1, _cookwareKey),
                _tabItem("Preparation", 2, _preparationKey),
              ],
            ),

            const SizedBox(height: 30),

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

            Container(
              key: _cookwareKey,
              child: CookwareSection(
                servings: servings,
                cookwareItems: _cookwareItems,
              ),
            ),

            const SizedBox(height: 35),

            Container(
              key: _preparationKey,
              child: PreparationSection(steps: _cookingSteps),
            ),

            const SizedBox(height: 35),

            ReviewSection(
  reviews: _reviewData,
  recipeName: widget.title,
),


            const SizedBox(height: 35),

            SimilarRecipesSection(recipes: _similarRecipeData),
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
              background: FutureBuilder<String?>(
                future: EnhancedRecipeImageService.getRecipeImage(widget.title, imageUrl: widget.image),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                        ),
                      ),
                    );
                  }
                  
                  if (snapshot.hasData && snapshot.data != null) {
                    final imageUrl = snapshot.data!;
                    if (imageUrl.startsWith('assets/')) {
                      return Image.asset(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                      );
                    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
                      return CachedImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(color: Colors.grey[300]),
                      );
                    } else {
                      return Container(color: Colors.grey[300]);
                    }
                  }
                  
                  return Container(color: Colors.grey[300]);
                },
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
                        recipeName: widget.title,
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
