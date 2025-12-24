import 'package:flutter/material.dart';
import '../preferences/cooking_preference_screen.dart';


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
    'Breads & Bakeries',
    'Snacks',
    'Beverages',
  ];

  String _selectedCategory = 'All';

  // ───────────────── INGREDIENT DATA ─────────────────
  final List<_Ingredient> _allIngredients = [
    _Ingredient(
      name: 'Aloe vera',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🌿',
    ),
    _Ingredient(
      name: 'Amaranth leaves',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🥬',
    ),
    _Ingredient(
      name: 'Avocado',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🥑',
    ),
    _Ingredient(
      name: 'Baby corn',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🌽',
    ),
    _Ingredient(
      name: 'Baby potatoes',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🥔',
    ),
    _Ingredient(
      name: 'Banana flower',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🍌',
    ),
    _Ingredient(
      name: 'Banana',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🍌',
    ),
    _Ingredient(
      name: 'Basil',
      category: 'Fruits & Vegetables',
      subtitle: 'Fruits & Vegetables',
      icon: '🌿',
    ),
    // you can add more categories/items here…
  ];

  final Set<String> _selectedNames = {};

  @override
  Widget build(BuildContext context) {
    final ingredients = _selectedCategory == 'All'
        ? _allIngredients
        : _allIngredients
            .where((i) => i.category == _selectedCategory)
            .toList();

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

          const Divider(height: 1),

          // ───────── LIST OF INGREDIENTS ─────────
          Expanded(
            child: ListView.separated(
              itemCount: ingredients.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = ingredients[index];
                final bool isChecked = _selectedNames.contains(item.name);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFF3E6),
                    child: Text(
                      item.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
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
                  trailing: Checkbox(
                    value: isChecked,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    activeColor: kAccent,
                    onChanged: (_) {
                      setState(() {
                        if (isChecked) {
                          _selectedNames.remove(item.name);
                        } else {
                          _selectedNames.add(item.name);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _selectedNames.remove(item.name);
                      } else {
                        _selectedNames.add(item.name);
                      }
                    });
                  },
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
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
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
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CookingPreferenceScreen(ingredients: []), // Pass the actual ingredients list here
    ),
  );
},

              child: const Text(
                'Next',
                style: TextStyle(
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
}

// ───────────────── MODEL ─────────────────
class _Ingredient {
  final String name;
  final String category;
  final String subtitle;
  final String icon;

  const _Ingredient({
    required this.name,
    required this.category,
    required this.subtitle,
    required this.icon,
  });
}
