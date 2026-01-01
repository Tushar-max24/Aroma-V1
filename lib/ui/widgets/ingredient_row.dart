import 'package:flutter/material.dart';
import 'dart:io';
import '../../../data/services/ingredient_image_service.dart';
import '../../../core/utils/item_image_resolver.dart';

class IngredientRow extends StatelessWidget {
  final String emoji;
  final String name;
  final int matchPercent;
  final VoidCallback onRemove;
  final bool useImageService;

  const IngredientRow({
    super.key,
    required this.emoji,
    required this.name,
    required this.matchPercent,
    required this.onRemove,
    this.useImageService = true,
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
          // Dynamic ingredient image/emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: useImageService
                ? FutureBuilder<String?>(
                    future: IngredientImageService.getIngredientImage(name),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        );
                      }
                      
                      if (snapshot.hasData && snapshot.data != null) {
                        final imagePath = snapshot.data!;
                        // Check if it's a local file path or asset path
                        if (imagePath.startsWith('assets/')) {
                          return Image.asset(
                            imagePath,
                            width: 40,
                            height: 40,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _buildEmojiFallback(),
                          );
                        } else {
                          // For local file paths, check if file exists first
                          final file = File(imagePath);
                          if (file.existsSync()) {
                            return Image.file(
                              file,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildEmojiFallback(),
                            );
                          } else {
                            // File doesn't exist, fallback to emoji
                            return _buildEmojiFallback();
                          }
                        }
                      }
                      
                      return _buildEmojiFallback();
                    },
                  )
                : _buildEmojiFallback(),
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
  
  Widget _buildEmojiFallback() {
    return Center(
      child: Text(
        emoji.isNotEmpty ? emoji : ItemImageResolver.getEmojiForIngredient(name),
        style: const TextStyle(fontSize: 30),
      ),
    );
  }
}

