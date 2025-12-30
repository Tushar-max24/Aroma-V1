import 'package:flutter/material.dart';

class IngredientRow extends StatelessWidget {
  final String emoji;
  final String name;
  final int matchPercent;
  final VoidCallback onRemove;

  const IngredientRow({
    super.key,
    required this.emoji,
    required this.name,
    required this.matchPercent,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Row(
        children: [
          // Emoji avatar (slightly larger)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + match text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'match: $matchPercent%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          // Remove button (x)
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE5E5),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Color(0xFFFF6A6A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

