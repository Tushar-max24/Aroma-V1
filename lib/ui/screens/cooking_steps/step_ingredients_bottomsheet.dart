import 'package:flutter/material.dart';
import '../../../data/services/emoji_service.dart';

class StepIngredientsBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> stepIngredients;
  final List<Map<String, dynamic>>? allIngredients;
  final int? currentStepIndex;
  bool get showAllIngredients => allIngredients != null;

  const StepIngredientsBottomSheet({
    super.key,
    required this.stepIngredients,
    this.allIngredients,
    this.currentStepIndex,
  });

  @override
  State<StepIngredientsBottomSheet> createState() => _StepIngredientsBottomSheetState();
}

class _StepIngredientsBottomSheetState extends State<StepIngredientsBottomSheet> {
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

  Widget _buildIngredientIcon(String? emoji) {
    if (emoji != null && emoji.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 30),
        ),
      );
    }
    return _buildDefaultIngredientIcon();
  }

  Widget _buildDefaultIngredientIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Image.asset(
        'assets/images/pantry/temp_pantry.png',
        width: 30,
        height: 30,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.fastfood, size: 30, color: Colors.grey),
      ),
    );
  }

  List<Map<String, dynamic>> get _ingredientsToShow {
    if (widget.showAllIngredients) {
      // When showing all ingredients, return them directly
      return widget.allIngredients ?? [];
    } else {
      // When showing step-specific ingredients, return them
      return widget.stepIngredients;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEmojiInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final ingredients = _ingredientsToShow;
    
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
                    widget.showAllIngredients ? "All Ingredients" : "Ingredients for This Step",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (widget.allIngredients != null && widget.currentStepIndex != null)
                    TextButton(
                      onPressed: () {
                        // This will trigger a rebuild with the opposite state
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StepIngredientsBottomSheet(
                            stepIngredients: widget.stepIngredients,
                            allIngredients: widget.showAllIngredients ? null : widget.allIngredients,
                            currentStepIndex: widget.showAllIngredients ? widget.currentStepIndex : null,
                          ),
                        );
                      },
                      child: Text(
                        widget.showAllIngredients ? "Show This Step Only" : "Show All Ingredients",
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
              if (ingredients.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'No ingredients found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: SingleChildScrollView(
                  child: Column(
                    children: ingredients.map<Widget>(
                      (item) {
                        // Get the name and quantity with fallbacks
                        final name = (item['name'] ?? item['ingredient'] ?? item['item'] ?? 'Ingredient').toString().trim();
                        final qty = (item['qty'] ?? item['quantity'] ?? item['amount'] ?? '').toString();
                        final emoji = _emojiService.getEmojiForIngredient(name);

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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // EMOJI OR DEFAULT ICON
                              _buildIngredientIcon(emoji),

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
                                    if (qty.isNotEmpty) ...[
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