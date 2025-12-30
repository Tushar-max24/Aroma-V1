import 'package:flutter/material.dart';
import '../../../data/services/emoji_service.dart';
import '../cooking_steps/cooking_steps_screen.dart';

final List<Map<String, dynamic>> cookingStepsModel = [
  // ---------------- STEP 1 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Soak the "),
      TextSpan(text: "whole black lentils (urad dal)", style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: " and "),
      TextSpan(text: "red kidney beans (rajma)", style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: " overnight for about "),
      TextSpan(text: "8–10 hours.", style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: " Drain and rinse them well."),
    ],
    "ingredients": [
      {"icon": "🥣", "name": "Whole black lentils", "qty": "1 cup (200g)"},
      {"icon": "🫘", "name": "Red kidney beans (rajma)", "qty": "½ cup (50g)"},
    ],
    "tips": [
      "Use filtered water for better soaking.",
      "Rinse thoroughly before cooking."
    ]
  },

  // ---------------- STEP 2 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Pressure cook the soaked lentils and rajma with salt for "),
      TextSpan(text: "8–10 whistles.", style: TextStyle(fontWeight: FontWeight.bold)),
    ],
    "ingredients": [
      {"icon": "🧂", "name": "Salt", "qty": "1 tsp"},
    ],
    "tips": [
      "Cooking time may vary based on cooker size.",
      "Ensure beans are soft before the next step."
    ]
  },

  // ---------------- STEP 3 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Sauté "),
      TextSpan(text: "onions, ginger, garlic & green chilies", style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: " in butter until golden brown."),
    ],
    "ingredients": [
      {"icon": "🧅", "name": "Onion", "qty": "1 medium"},
      {"icon": "🧄", "name": "Garlic", "qty": "5 cloves"},
    ],
    "tips": [
      "Do not burn garlic; sauté on medium flame.",
    ]
  },

  // ---------------- STEP 4 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Add tomato puree and spices, then cook until "),
      TextSpan(text: "oil separates.", style: TextStyle(fontWeight: FontWeight.bold)),
    ],
    "ingredients": [
      {"icon": "🍅", "name": "Tomato puree", "qty": "1 cup"},
      {"icon": "🌶", "name": "Spices mix", "qty": "2 tsp"},
    ],
    "tips": [
      "Stir continuously to avoid burning.",
    ]
  },

  // ---------------- STEP 5 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Add cooked dal mixture and simmer for "),
      TextSpan(text: "25–30 minutes.", style: TextStyle(fontWeight: FontWeight.bold)),
    ],
    "ingredients": [
      {"icon": "🥣", "name": "Cooked dal", "qty": "All prepared"},
    ],
    "tips": [
      "Slow simmering gives deeper flavor.",
    ]
  },

  // ---------------- STEP 6 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Add cream, butter & "),
      TextSpan(text: "kasuri methi", style: TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: ". Mix well."),
    ],
    "ingredients": [
      {"icon": "🧈", "name": "Butter", "qty": "3 tbsp"},
      {"icon": "🥛", "name": "Fresh cream", "qty": "¼ cup"},
      {"icon": "🍃", "name": "Kasuri methi", "qty": "1 tsp"},
    ],
    "tips": [
      "Do not boil after adding cream—it may curdle.",
    ]
  },

  // ---------------- STEP 7 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Smoke using hot charcoal for "),
      TextSpan(text: "restaurant-style flavour.", style: TextStyle(fontWeight: FontWeight.bold)),
    ],
    "ingredients": [
      {"icon": "🔥", "name": "Charcoal", "qty": "1 small piece"},
    ],
    "tips": [
      "Place charcoal in a small bowl and pour ghee on top.",
    ]
  },

  // ---------------- STEP 8 ----------------
  {
    "rich_instruction": [
      TextSpan(text: "Serve hot with "),
      TextSpan(text: "naan or jeera rice.", style: TextStyle(fontWeight: FontWeight.bold)),
    ],
    "ingredients": [
      {"icon": "🍛", "name": "Jeera rice / Naan", "qty": "As needed"},
    ],
    "tips": [
      "Garnish with cream for best presentation.",
    ]
  },
];

class _IngredientsNeededScreenState extends State<IngredientsNeededScreen> {
  final EmojiService _emojiService = EmojiService();
  bool _isEmojiInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEmojiService();
  }

  Future<void> _initializeEmojiService() async {
    await _emojiService.initialize();
    if (mounted) {
      setState(() {
        _isEmojiInitialized = true;
      });
    }
  }

  Widget _buildDefaultIngredientIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Image.asset(
        'assets/images/pantry/temp_pantry.png', 
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 30, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- BACK BUTTON ----------------
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- TITLE (BOLD) ----------------
              const Text(
                "Ingredients Needed",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- INFO BOX EXACT LIKE SCREENSHOT ----------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),  // EXACT GREY BACKGROUND
                  borderRadius: BorderRadius.circular(18),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      const TextSpan(
                        text: "Make sure you have all ingredients\nfor ",
                      ),
                      TextSpan(
                        text: "${widget.servings} serving",
                        style: const TextStyle(
                          color: Color(0xFFFF6A45),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ---------------- INGREDIENT BOX LIST ----------------
              Expanded(
                child: ListView.separated(
                  itemCount: widget.ingredients.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: Color(0xFFE5E5E5),
                  ),
                  itemBuilder: (context, index) {
                    if (!_isEmojiInitialized) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final item = widget.ingredients[index];
                    // Get the name and quantity with fallbacks
                    final name = (item['name'] ?? item['ingredient'] ?? item['item'] ?? 'Ingredient').toString().trim();
                    // Get quantity with proper fallbacks and handle serving size adjustment
                    final baseQty = item['qty'] ?? item['quantity'] ?? item['amount'] ?? 1;
                    final qty = (baseQty is num && widget.servings > 0)
                        ? (baseQty * widget.servings).toString()
                        : baseQty.toString();
                    
                    // Get emoji for the ingredient
                    final emoji = _emojiService.getEmojiForIngredient(name);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // EMOJI OR DEFAULT ICON
                          if (emoji != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 30),
                              ),
                            )
                          else
                            _buildDefaultIngredientIcon(),

                          // NAME + QUANTITY
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  qty,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF7A7A7A),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ---------------- BOTTOM BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Create a default step if steps is empty or null
                    List<Map<String, dynamic>> stepsToPass = [];
                    
                    if (widget.steps.isNotEmpty) {
                      // Ensure all steps have the required fields
                      stepsToPass = widget.steps.map((step) {
                        return {
                          'instruction': step['instruction']?.toString() ?? 'Continue cooking',
                          'ingredients': (step['ingredients'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [],
                          'tips': (step['tips'] as List?)?.whereType<String>().toList() ?? [],
                          if (step['rich_instruction'] != null) 'rich_instruction': step['rich_instruction'],
                        };
                      }).toList();
                    } else {
                      // Create a default step
                      stepsToPass = [
                        {
                          'instruction': 'Follow the recipe instructions',
                          'ingredients': widget.ingredients.map((ingredient) {
                            final emoji = _emojiService.getEmojiForIngredient(
                              ingredient['name'] ?? ingredient['ingredient'] ?? ingredient['item'] ?? 'Ingredient'
                            );
                            return {
                              'name': ingredient['name'] ?? ingredient['ingredient'] ?? ingredient['item'] ?? 'Ingredient',
                              'emoji': emoji,
                              'qty': ingredient['qty'] ?? ingredient['quantity'] ?? ingredient['amount'] ?? 'as needed',
                            };
                          }).toList(),
                          'tips': ['Make sure to follow the recipe carefully']
                        }
                      ];
                    }
                    
                    if (stepsToPass.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CookingStepsScreen(
                            steps: stepsToPass,
                            currentStep: 0, // Start from the first step (index 0)
                            allIngredients: widget.ingredients,
                          ),
                        ),
                      );
                    } else {
                      // Handle case where there are no steps
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No cooking steps available')),
                      );
                    }
                  },
                  child: const Text(
                    "Let's Start",
                    style: TextStyle(
                      color: Colors.black,   // BLACK TEXT
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class IngredientsNeededScreen extends StatefulWidget {
  final int servings;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;

  const IngredientsNeededScreen({
    super.key,
    required this.servings,
    required this.ingredients,
    required this.steps,
  });

  @override
  State<IngredientsNeededScreen> createState() => _IngredientsNeededScreenState();
}