import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../preferences/cooking_preference_screen.dart';
import '../home/generate_recipe_screen.dart';
import '../../../state/pantry_state.dart';
import '../../../core/utils/category_engine.dart';


const Color kAccent = Color(0xFFFF7A4A);

class SelectIngredientsScreen extends StatefulWidget {
  const SelectIngredientsScreen({super.key});

  @override
  State<SelectIngredientsScreen> createState() =>
      _SelectIngredientsScreenState();
}

class _SelectIngredientsScreenState extends State<SelectIngredientsScreen> {
  // ───────────────── CATEGORIES ─────────────────
  final List<String> _categories = [
    'All',
    'Fruits & Vegetables',
    'Dairy & Alternatives',
    'Eggs, Meat & Fish',
    'Grains & Staples',
    'Spices & Masalas',
    'Oils & Condiments',
    'Ready-to-Eat',
    'Nuts & Dry Fruits',
    'Snacks & Bakery',
    'Beverages',
    'Others',
  ];

  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<_Ingredient> _allIngredients = [];
  Set<String> _selectedIngredients = {};

  @override
  void initState() {
    super.initState();
    _loadPantryIngredients();
  }

  Future<void> _loadPantryIngredients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use PantryState provider instead of manual parsing
      final pantryState = Provider.of<PantryState>(context, listen: false);
      await pantryState.loadPantry(); // Ensure pantry is loaded
      
      // Convert pantry ingredients to _Ingredient objects with image URLs
      final ingredients = pantryState.pantryItems.map((item) => _Ingredient(
        name: item.name,
        category: CategoryEngine.getCategory(item.name),
        subtitle: CategoryEngine.getCategory(item.name),
        icon: _getIconForIngredient(item.name),
        imageUrl: item.imageUrl, // Include imageUrl
      )).toList();

      setState(() {
        _allIngredients = ingredients;
        _isLoading = false;
      });

      print("🔍 DEBUG: Loaded ${ingredients.length} pantry ingredients for selection");
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("❌ Error loading pantry ingredients: $e");
    }
  }

  String _getIconForIngredient(String ingredient) {
    final lower = ingredient.toLowerCase();
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('orange')) return '🍊';
    if (lower.contains('pomegranate') || lower.contains('anar')) return '🍎';
    if (lower.contains('carrot')) return '🥕';
    if (lower.contains('tomato')) return '🍅';
    if (lower.contains('onion')) return '🧅';
    if (lower.contains('potato')) return '🥔';
    if (lower.contains('garlic')) return '🧄';
    if (lower.contains('ginger')) return '🫚';
    if (lower.contains('milk')) return '🥛';
    if (lower.contains('cheese')) return '🧀';
    if (lower.contains('yogurt') || lower.contains('curd')) return '🥛';
    if (lower.contains('egg')) return '🥚';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('fish')) return '🐟';
    if (lower.contains('bread')) return '🍞';
    if (lower.contains('nuts') || lower.contains('almond') || lower.contains('cashew')) return '🥜';
    if (lower.contains('rice') || lower.contains('atta') || lower.contains('flour')) return '🌾';
    if (lower.contains('oil') || lower.contains('ghee')) return '🫒';
    if (lower.contains('spice') || lower.contains('powder') || lower.contains('masala')) return '🌶️';
    return '🥗'; // Default icon
  }

  void _toggleIngredientSelection(String ingredientName) {
    setState(() {
      if (_selectedIngredients.contains(ingredientName)) {
        _selectedIngredients.remove(ingredientName);
      } else {
        _selectedIngredients.add(ingredientName);
      }
    });
  }

  void _selectAllIngredients() {
    setState(() {
      _selectedIngredients = Set.from(_allIngredients.map((ing) => ing.name));
    });
  }

  void _deselectAllIngredients() {
    setState(() {
      _selectedIngredients.clear();
    });
  }

  List<_Ingredient> get _filteredIngredients {
    if (_selectedCategory == 'All') {
      return _allIngredients;
    }
    return _allIngredients.where((ing) => ing.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: kAccent),
        ),
      );
    }

    final ingredients = _filteredIngredients;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Ingredients',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // search action – optional
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
        ],
      ),

      // BODY
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ───────── CATEGORY CHIPS ROW ─────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final bool selected = cat == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? kAccent : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color:
                            selected ? kAccent : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // ───────── SELECT ALL/DESELECT ALL ROW ─────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_selectedIngredients.length} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedIngredients.length == _allIngredients.length
                      ? _deselectAllIngredients
                      : _selectAllIngredients,
                  child: Text(
                    _selectedIngredients.length == _allIngredients.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      color: kAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ───────── LIST OF INGREDIENTS ─────────
          Expanded(
            child: ListView.separated(
              itemCount: ingredients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = ingredients[index];
                final bool isChecked = _selectedIngredients.contains(item.name);

                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (bool? value) {
                    _toggleIngredientSelection(item.name);
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  secondary: Container(
                    width: 44,
                    height: 44,
                    child: item.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              item.imageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildEmojiFallback(item.icon),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildEmojiFallback(item.icon);
                              },
                            ),
                          )
                        : _buildEmojiFallback(item.icon),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  activeColor: kAccent,
                );
              },
            ),
          ),
        ],
      ),

      // ───────── BOTTOM NEXT BUTTON ─────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                if (_selectedIngredients.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one ingredient'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final selectedList = _selectedIngredients.toList();
                print("🔍 DEBUG: Selected ingredients for recipe generation: $selectedList");
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenerateRecipeScreen(
                      usePantryIngredients: true,
                      pantryIngredients: selectedList,
                    ),
                  ),
                );
              },
              child: Text(
                _selectedIngredients.isEmpty 
                    ? 'Select Ingredients' 
                    : 'Generate Recipes (${_selectedIngredients.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build emoji fallback
  Widget _buildEmojiFallback(String emoji) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFFFF3E6),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}

// ───────────────── MODEL ─────────────────
class _Ingredient {
  final String name;
  final String category;
  final String subtitle;
  final String icon;
  final String? imageUrl; // Add imageUrl field

  const _Ingredient({
    required this.name,
    required this.category,
    required this.subtitle,
    required this.icon,
    this.imageUrl, // Add to constructor
  });
}
