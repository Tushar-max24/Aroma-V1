import 'package:flutter/material.dart';
import 'ingredient_section.dart';
import 'cookware_section.dart';
import 'preparation_section.dart';
import 'review_section.dart';
import 'similar_recipes_section.dart';
import '../ingredients_needed/ingredients_needed_screen.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/services/api_client.dart';
import '../../../state/pantry_state.dart';
import 'package:provider/provider.dart';
import '../../../data/services/gemini_recipe_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String image;
  final String title;
  final List<Map<String, dynamic>> ingredients;
  final String cuisine;
  final String cookTime;
  final int servings;

  const RecipeDetailScreen({
    super.key,
    required this.image,
    required this.title,
    required this.ingredients,
    required this.cuisine,
    required this.cookTime,
    required this.servings,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Map<String, dynamic>? aiData;
  bool aiLoading = true;
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
    _fetchAIData();
  }

  void _scrollTo(GlobalKey key) {
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchAIData() async {
    try {
      final result = await GeminiRecipeService.fetchRecipeData(widget.title);
      setState(() {
        aiData = result;
        _cookwareItems = List<String>.from(result["cookware"] ?? []);
        _cookingSteps = List<String>.from(result["steps"] ?? [])
            .where((step) => step != null && step.isNotEmpty)
            .map((step) => step.toString())
            .toList();
        _similarRecipeData =
            List<String>.from(result["similar_recipes"] ?? [])
                .where((e) => e != null && e.isNotEmpty)
                .map((e) => {"title": e.toString()})
                .toList();
        aiLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching recipe data: $e');
      setState(() {
        _cookingSteps = [];
        aiLoading = false;
      });
    }
  }

  Widget _content() {
    final nutrition = aiData?["nutrition"] ?? {};

    return Consumer<PantryState>(
      builder: (_, pantryState, __) {
        final pantryItems = pantryState.pantryItems;

        final availableIngredients = widget.ingredients.where((ingredient) {
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
                    label: nutrition["calories"]?.toString() ?? "--"),
                _InfoChip(icon: Icons.access_time, label: widget.cookTime),
                _InfoChip(icon: Icons.people, label: servings.toString()),
              ],
            ),

            const SizedBox(height: 22),

            AnimatedCrossFade(
              firstChild: Text(
                aiData?["description"] ?? "Generating recipe description...",
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              secondChild: Text(aiData?["description"] ?? ""),
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
                    label: nutrition["carbs"] ?? "--"),
                _NutritionTile(
                    icon: Icons.fitness_center,
                    label: nutrition["protein"] ?? "--"),
                _NutritionTile(
                    icon: Icons.local_fire_department,
                    label: nutrition["calories"]?.toString() ?? "--"),
                _NutritionTile(
                    icon: Icons.lunch_dining,
                    label: nutrition["fat"] ?? "--"),
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
                ingredientData: widget.ingredients,
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
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
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
