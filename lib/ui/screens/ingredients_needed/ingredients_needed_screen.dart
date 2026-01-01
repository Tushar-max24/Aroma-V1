import 'package:flutter/material.dart';
import 'dart:io';
import '../cooking_steps/cooking_steps_screen.dart';
import '../../../data/services/ingredient_image_service.dart';
import '../../../core/utils/item_image_resolver.dart';

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
      {"icon": "", "name": "Whole black lentils", "qty": "1 cup (200g)"},
      {"icon": "", "name": "Red kidney beans (rajma)", "qty": "½ cup (50g)"},
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
      {"icon": "", "name": "Salt", "qty": "1 tsp"},
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
      {"icon": "", "name": "Onion", "qty": "1 medium"},
      {"icon": "", "name": "Garlic", "qty": "5 cloves"},
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
      {"icon": "", "name": "Tomato puree", "qty": "1 cup"},
      {"icon": "", "name": "Spices mix", "qty": "2 tsp"},
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
      {"icon": "", "name": "Cooked dal", "qty": "All prepared"},
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
      {"icon": "", "name": "Butter", "qty": "3 tbsp"},
      {"icon": "", "name": "Fresh cream", "qty": "¼ cup"},
      {"icon": "", "name": "Kasuri methi", "qty": "1 tsp"},
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
      {"icon": "", "name": "Charcoal", "qty": "1 small piece"},
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
      {"icon": "", "name": "Jeera rice / Naan", "qty": "As needed"},
    ],
    "tips": [
      "Garnish with cream for best presentation.",
    ]
  },
];

class IngredientsNeededScreen extends StatelessWidget {
  final int servings;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> steps;
  final String recipeName;

  const IngredientsNeededScreen({
    super.key,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.recipeName,
  });

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

  Widget _buildDynamicIngredientIcon(String ingredientName) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FutureBuilder<String?>(
        future: IngredientImageService.getIngredientImage(ingredientName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            final imagePath = snapshot.data!;
            if (imagePath.startsWith('assets/')) {
              return Image.asset(
                imagePath,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildEmojiIcon(ingredientName),
              );
            } else {
              // For local file paths, check if file exists first
              final file = File(imagePath);
              if (file.existsSync()) {
                return Image.file(
                  file,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildEmojiIcon(ingredientName),
                );
              } else {
                // File doesn't exist, fallback to emoji
                return _buildEmojiIcon(ingredientName);
              }
            }
          }
          
          return _buildEmojiIcon(ingredientName);
        },
      ),
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Text(
        ItemImageResolver.getEmojiForIngredient(ingredientName),
        style: const TextStyle(fontSize: 30),
      ),
    );
  }

  Widget _buildIngredientIcon(dynamic icon, String ingredientName) {
    // If we have an emoji, use it
    if (icon is String && icon.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          icon,
          style: const TextStyle(fontSize: 30),
        ),
      );
    }
    // Use dynamic ingredient image service
    return _buildDynamicIngredientIcon(ingredientName);
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
                        text: "$servings serving",
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
                  itemCount: ingredients.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    thickness: 0.7,
                    color: Color(0xFFE5E5E5),
                  ),
                  itemBuilder: (context, index) {
                    final item = ingredients[index];
                    // Get the name and quantity with fallbacks
                    final name = (item['name'] ?? item['ingredient'] ?? item['item'] ?? 'Ingredient').toString();
                    final qty = (item['qty'] ?? item['quantity'] ?? item['amount'] ?? 'as needed').toString();
                    final icon = item['icon'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          // DYNAMIC ICON
                          _buildIngredientIcon(icon, name),

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

              const SizedBox(height: 16),

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
                    
                    if (steps.isNotEmpty) {
                      // Ensure all steps have the required fields
                      stepsToPass = steps.map((step) {
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
                          'ingredients': ingredients,
                          'tips': ['Make sure to follow the recipe carefully']
                        }
                      ];
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CookingStepsScreen(
                          steps: stepsToPass,              // detailed steps
                          currentStep: 1,
                          allIngredients: ingredients,
                          recipeName: recipeName,
                        ),
                      ),
                    );
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