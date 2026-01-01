import 'package:flutter/material.dart';
import 'dart:io';
import '../../../data/services/ingredient_image_service.dart';
import '../../../core/utils/item_image_resolver.dart';

class StepIngredientsBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> stepIngredients;
  final List<Map<String, dynamic>>? allIngredients;
  final int? currentStepIndex;
  bool get showAllIngredients => allIngredients != null && currentStepIndex != null;

  const StepIngredientsBottomSheet({
    super.key,
    required this.stepIngredients,
    this.allIngredients,
    this.currentStepIndex,
  });

  Widget _buildIngredientIcon(dynamic icon, String ingredientName) {
    // If we have an emoji, use it
    if (icon is String && icon.isNotEmpty && !icon.startsWith('assets/')) {
      return Padding(
        padding: const EdgeInsets.only(right: 0),
        child: Text(
          icon,
          style: const TextStyle(fontSize: 30),
        ),
      );
    }
    
    // Use dynamic ingredient image service
    return FutureBuilder<String?>(
      future: IngredientImageService.getIngredientImage(ingredientName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 30,
            height: 30,
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
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildEmojiIcon(ingredientName),
            );
          } else {
            // For local file paths, check if file exists first
            final file = File(imagePath);
            if (file.existsSync()) {
              return Image.file(
                file,
                width: 30,
                height: 30,
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
    );
  }

  Widget _buildEmojiIcon(String ingredientName) {
    return Text(
      ItemImageResolver.getEmojiForIngredient(ingredientName),
      style: const TextStyle(fontSize: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        /// =================== WHITE SHEET ===================
        Container(
          margin: const EdgeInsets.only(top: 60),
          padding: const EdgeInsets.fromLTRB(20, 38, 20, 30),
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE & TOGGLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showAllIngredients ? "All Ingredients" : "Ingredients for This Step",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (allIngredients != null)
                    TextButton(
                      onPressed: () {
                        // This will trigger a rebuild with the opposite state
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StepIngredientsBottomSheet(
                            stepIngredients: stepIngredients,
                            allIngredients: showAllIngredients ? null : allIngredients,
                            currentStepIndex: showAllIngredients ? null : currentStepIndex,
                          ),
                        );
                      },
                      child: Text(
                        showAllIngredients ? "Show This Step Only" : "Show All Ingredients",
                        style: const TextStyle(
                          color: Color(0xFFFF6A45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= INGREDIENT BOX LIST =================
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    children: (showAllIngredients ? allIngredients! : stepIngredients).map<Widget>(
                      (item) {
                        // Handle the data structure from IngredientsNeededScreen
                        // The actual data has 'item', 'price', and 'quantity' keys
                        final name = (item['item'] ?? 'Ingredient').toString();
                        final qty = (item['quantity']?.toString() ?? '');
                        final icon = item['icon'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFFDCCD),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // ICON - Updated to use dynamic image loading
                              _buildIngredientIcon(icon, name),
                              const SizedBox(width: 14),

                              // NAME + QTY
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (qty.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        qty,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// =================== CLOSE ❌ BUTTON ===================
        Positioned(
          top: 4,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 46,
              width: 46,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}