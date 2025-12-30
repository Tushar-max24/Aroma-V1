import 'package:flutter/material.dart';

class IngredientRow extends StatelessWidget {
  final String? emoji;
  final String name;
  final int matchPercent;
  final VoidCallback onRemove;
  final String defaultImagePath;
  final VoidCallback? onEdit;

  static const String defaultIngredientImage = 'assets/images/pantry/temp_pantry.png';

  const IngredientRow({
    super.key,
    this.emoji,
    required this.name,
    required this.matchPercent,
    required this.onRemove,
    this.onEdit,
    this.defaultImagePath = defaultIngredientImage,
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
          // Emoji avatar or default image
          Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            child: emoji != null
                ? Text(
                    emoji!,
                    style: const TextStyle(fontSize: 48, height: 1.0),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      defaultImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.fastfood, size: 30, color: Colors.grey),
                      ),
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

          // Edit and Remove buttons
          Row(
            children: [
              // Edit button
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE5F1FF),
                    ),
                    child: const Center(
                      child: Text(
                        '📝',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
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
          )
        ],
      ),
    );
  }
}

