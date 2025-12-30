import 'package:flutter/material.dart';
import 'package:flavoryx/data/services/emoji_service.dart';

// ===============================
// INGREDIENT SECTION (DYNAMIC)
// ===============================
class IngredientSection extends StatefulWidget {
  const IngredientSection({
    super.key,
    required this.servings,
    required this.onServingChange,
    required this.ingredientData,
    this.availableIngredients = const [],
  });

  final int servings;
  final Function(int) onServingChange;
  final List<Map<String, dynamic>> ingredientData;
  final List<String> availableIngredients;

  @override
  State<IngredientSection> createState() => _IngredientSectionState();
}

class _IngredientSectionState extends State<IngredientSection> {
  late final EmojiService _emojiService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _emojiService = EmojiService();
    _initializeEmojiService();
  }

  Future<void> _initializeEmojiService() async {
    await _emojiService.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ingredients",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
"${widget.servings} Servings",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            IngredientStepper(
              servings: widget.servings,
              onChanged: widget.onServingChange,
            ),
          ],
        ),

        const SizedBox(height: 22),

        Column(
          children: widget.ingredientData.map((item) {
            final name = item['item']?.toString() ?? '';
            final qty = item['quantity'] ?? 1;

            return IngredientTile(
              name: name,
              quantity: _formatQuantity(qty, widget.servings),
              icon: _emojiForIngredient(name),
              isAvailable:
                  widget.availableIngredients.contains(name.toLowerCase()),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===============================
  // HELPERS
  // ===============================
  String _formatQuantity(dynamic baseQty, int servings) {
    final num qty =
        baseQty is num ? baseQty : num.tryParse(baseQty.toString()) ?? 1;
    final totalQty = qty * servings;
    // Format as integer if it's a whole number, otherwise show 1 decimal place
    return totalQty % 1 == 0 ? totalQty.toInt().toString() : totalQty.toStringAsFixed(1);
  }

  String _emojiForIngredient(String name) {
    return _emojiService.getEmojiForIngredient(name) ?? '🥬';
  }
}

// ===============================
// INGREDIENT TILE
// ===============================
class IngredientTile extends StatelessWidget {
  final String name;
  final String quantity;
  final String icon;
  final bool isAvailable;

  const IngredientTile({
    super.key,
    required this.name,
    required this.quantity,
    required this.icon,
    required this.isAvailable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          // Emoji/Icon
          Container(
            width: 60,
            height: 60,
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 36, height: 1.0),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name & Quantity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Qty: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: quantity,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Availability Indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// SERVING STEPPER
// ===============================
class IngredientStepper extends StatelessWidget {
  final int servings;
  final Function(int) onChanged;

  const IngredientStepper({
    super.key,
    required this.servings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      width: 194,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA58A),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(servings > 1 ? servings - 1 : 1),
            child: _btn("−"),
          ),
          Expanded(
            child: Center(
              child: Text(
                "$servings",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(servings + 1),
            child: _btn("+"),
          ),
        ],
      ),
    );
  }

  Widget _btn(String text) {
    return Container(
      width: 55,
      height: 45,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF6A45),
          ),
        ),
      ),
    );
  }
}
